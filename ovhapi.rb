# Copyright 2014-2015 Julien GIRARD 
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

require 'json'

class OvhApi

  def initialize()
    @references = Hash.new()
  end

  def set_data(json)
    # Erase previous informations 
    @references = Hash.new()

    # Parse answer
    data = JSON.parse(json)

    if data == nil
      raise JSON::JSONError, 'No data.'
    end

    # Look for 'answer' subsection
    if !data.include?('answer')
      raise JSON::JSONError, 'No section \'answer\'.'
    end

    # Check if the answer is valid
    if data['answer'] == nil
      raise JSON::JSONError, "Subsection \'answer\' is null. Returned data: '#{data}'."
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
