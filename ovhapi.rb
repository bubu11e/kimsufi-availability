#
# description : The class defined in this file is used to parse OVH availability API.
# author      : Julien Girard
#

require 'net/http'
require 'uri'
require 'json'

class OvhApi

  def initialize(url)
    @uri = URI.parse(url)
    @references = Hash.new()
  end

  def request
    # Erase previous informations 
    @references = Hash.new()

    # Request OVH API
    response = Net::HTTP.get_response(@uri)
    if response.code.to_i != 200
      raise "Request to OVH server has failed with http return code '#{response.code}'."
    end

    # Parse answer
    data = JSON.parse(response.body)

    if data == nil
      raise JSON::JSONError, 'No data.'
    end

    # Look for 'answer' subsection
    if !data.include?('answer')
      raise JSON::JSONError, 'No section \'answer\'.'
    end

    # Look for 'availability' subsection
    if !data['answer'].include?('availability')
      raise JSON::JSONError, 'No subsection \'availability\' in section \'answer\'.'
    end

    # Run through each avilability section
    availability_sections = data['answer']['availability']

    availability_sections.each { |availability_section|
      # Look for reference subsection
      if !availability_section.include?('reference')
        raise JSON::JSONError, 'No \'reference\' in \'availability\' subsection.'
      end

      # Look for zones subsection
      if !availability_section.include?('zones')
        raise JSON::JSONError, 'No \'zones\' specified in \'availability\' subsection.'
      end

      reference = availability_section['reference']
      zones = Array.new()

      # Run through each zone
      availability_section['zones'].each { |zone|
        # Look for availability subsection
        if !zone.include?('availability')
          raise JSON::JSONError, 'No \'availability\' specified in \'zones\' subsection.'
        end

        # Look for zone subsection
        if !zone.include?('zone')
          raise JSON::JSONError, 'No \'zone\' specified in \'zones\' subsection.'
        end

        # If the reference is available, we add it to the hash
        if zone['availability'] != 'unknown'
          zones.push(zone['zone'])
        end
      }

      @references[reference] = zones
    }
  end

  def include?(reference)
    return @references.include?(reference)
  end

  def get_availability(reference)
    return @references[reference]
  end
end
