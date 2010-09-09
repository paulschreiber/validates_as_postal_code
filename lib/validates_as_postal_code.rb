module ActiveRecord
  module Validations
    module ClassMethods

  		def postal_code_regex_for_country(country_code)
  		  if country_code.blank?
  		    nil
  		  elsif ["AU", "NZ"].include?(country_code)
  		    /\d{4}/
  		  elsif ["US"].include?(country_code)
  		    /\d{5}(-\d{4})?/
  		  elsif ["CA"].include?(country_code)
  		    /[ABCEGHJKLMNPRSTVXY]\d[ABCEGHJKLMNPRSTWVXYZ]\d[ABCEGHJKLMNPRSTWVXYZ]\d/
  		  else
  		    nil
  		  end
  		end

  		def disallowed_characters_for_country(country_code)
  		  if country_code.blank?
  		    nil
  		  elsif ["US", "AU", "NZ"].include?(country_code)
  		    /[^0-9]/
  		  elsif ["CA", "UK"].include?(country_code)
  		    /[^0-9A-Z]/
  		  else
  		    nil
  		  end
  		end

  		def validates_as_postal_code(*args)        
  		  configuration = { :message => ActiveRecord::Errors.default_error_messages[:invalid],
  		                    :on => :save, :with => nil
  		                  }
  		  configuration.update(args.pop) if args.last.is_a?(Hash)

  		  validates_each(args, configuration) do |record, attr_name, value|
          if configuration[:country].is_a?(String)
            country = configuration[:country]
          elsif configuration[:country].is_a?(Symbol) and record.respond_to?(configuration[:country])
            country = record.send(configuration[:country])
          elsif record.respond_to?(:country)
            country = record.send(:country)
          else
            country = false
          end

          next unless country
    		  current_regex = postal_code_regex_for_country(country)
    		  next unless current_regex
    		  disallowed_characters = disallowed_characters_for_country(country)

  		    new_value = value.nil? ? "" : value.upcase.gsub(disallowed_characters, '')

  		    unless (configuration[:allow_blank] && new_value.blank?) || new_value =~ current_regex
  		      record.errors.add(attr_name, configuration[:message])
  		    else
  		      record.send(attr_name.to_s + '=',
  		        format_as_postal_code(new_value, country, disallowed_characters)
  		      ) if configuration[:set]
  		    end
  		  end
  		end

  		def format_as_postal_code(arg, country_code, disallowed_characters)
  		  return nil if (arg.blank? or country_code.blank? or !postal_code_regex_for_country(country_code))

  		  postal_code = arg.gsub(disallowed_characters, '')

  		  if ["US"].include?(country_code)
  		    digit_count = postal_code.length
  		    if digit_count == 5
  		      return postal_code
  		    elsif digit_count == 9
  		      return "%s-%s" % [postal_code[0..4], postal_code[5..8]]
  		    else
  		      return nil
  		    end
  
  		  elsif ["AU", "NZ"].include?(country_code)
  		    postal_code

  		  elsif ["CA"].include?(country_code)
  		    fsa = postal_code[0..2]
  		    lda = postal_code[3..5]

  		    postal_code = "%s %s" % [fsa, lda]
  		    postal_code.upcase
  		  end
  		end

    end    
  end
end
