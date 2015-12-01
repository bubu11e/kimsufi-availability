#!/usr/bin/env ruby
#
# decription : This script parses the OVH API and exec the specified commands when the offer you are looking for is available.
# author     : Julien Girard
#

require 'net/http'
require 'uri'
require 'json'
require 'optparse'
require 'logger'
require 'io/console'
require_relative 'ovhapi'

# Define logger
logger = Logger.new(STDOUT)
logger.level = Logger::ERROR

# Define constant
# URL of the OVH availability API
url = 'https://ws.ovh.com/dedicated/r2/ws.dispatcher/getAvailability2'

# References of Kimsufi offers
references = {
 'KS-1'     => '150sk10',
 'KS-2'     => '150sk20',
 'KS-2 SSD' => '150sk22',
 'KS-3'     => '150sk30',
 'KS-4'     => '150sk40',
 'KS-5'     => '150sk50',
 'KS-6'     => '150sk60'
}

# Zones where Kimsufi offers are available
zones = {
  'gra' => 'Gravelines',
  'sbg' => 'Strasbourg',
  'rbx' => 'Roubaix',
  'bhs' => 'Beauharnois'
}

# Define default options of the script
options = {}
options[:verbose] = false
options[:loop] = false
options[:interval] = 0
options[:offers] = references.keys 
options[:commands] = []
options[:proxy_addr] = nil
options[:proxy_port] = nil
options[:proxy_user] = nil
options[:proxy_pass] = nil

# Parse user specified options
OptionParser.new do |opts|
  opts.banner = "Usage: ./kimsufi-availability.rb [options]"

  # Verbose option
  opts.on('-v', '--[no-]verbose', 'Run verbosely.') do |v|
    options[:verbose] = v
    logger.level = Logger::INFO
  end

  # Loop option
  opts.on('-l N', '--loop N', Integer, 'When this option is set, the script will check the OVH API every N seconds.') do |n|
    puts 'Press Ctrl+C at any time to terminate the script.'
    trap('INT') { puts 'Shutting down.'; exit}
    options[:loop] = true
    options[:interval] = n
  end

  # Offers option
  opts.on('-o x,y,z', '--offers x,y,z', Array, "List offers to watch in the list #{options[:offers]}.") do |offers|
    options[:offers] = offers
  end

  # Commands option
  opts.on('-c x,y,z', '--commands x,y,z', Array, 'List of commands to execute on offer availability (firefox https://www.kimsufi.com/fr/commande/kimsufi.xml?reference=150sk10).') do |commands|
    options[:commands] = commands
  end

  # Proxy option
  opts.on('-p', '--proxy [addr:port]', String, 'Addresse of the proxy server to use to request ovh api.') do |proxy|
    split = proxy.split(':')
    options[:proxy_addr] = split.length > 0 ? split[0] : nil
    options[:proxy_port] = split.length > 1 ? split[1] : nil
  end

  # User proxy option
  opts.on('-u', '--user [user]', String, 'User to use for proxy authentification. Password will be asked dynamically.') do |user|
    options[:proxy_user] = user
    puts('Proxy password ?')
    pass = STDIN.noecho(&:gets).chomp
    options[:proxy_pass] = pass.empty? ? nil : pass
  end

end.parse!

# Initialize api interface
api = OvhApi.new()

uri = URI(url)
request = Net::HTTP::Get.new uri

Net::HTTP.start(uri.host, uri.port, options[:proxy_addr], options[:proxy_port], options[:proxy_user], options[:proxy_pass], {:use_ssl => true, :keep_alive_timeout => (10 + options[:interval].to_i)})do |http|
  begin
    # Request OVH api
    response = http.request request
    # Apply received data to ovh api class
    api.set_data(response.body)
  
    options[:offers].each do |offer|
      # Retrieve reference of the current offer
      reference = references.include?(offer) ? references[offer] : offer
    
      # Check if the reference is in api
      if api.include?(reference)
        availability = []

        # Retrieve available zone for the specified reference
        api.get_availability(reference).each do |zone|
          availability.push(zones.include?(zone) ? zones[zone] : zone)
        end

        if availability.length > 0
          logger.info("Offer #{offer} currently available in the following locations: #{availability}.")

          # The offer is available, we execute the list of commands
          options[:commands].each do |command|
            logger.info("About to execute command: '#{command}'.")
            if system(command)
              logger.info("Command executed successfully.")
            else
              logger.error("Command failed.")
            end
          end
        else
          # The offer is currently unavailable
          logger.info("Offer #{offer} currently not available.")
        end

      else
        logger.error("Offer #{offer}(reference: #{reference} not present in api.)")
      end
    end

    # Wait before retry
    sleep options[:interval]
  end while options[:loop]
end
