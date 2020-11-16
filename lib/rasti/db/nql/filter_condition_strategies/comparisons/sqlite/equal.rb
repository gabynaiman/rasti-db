module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module SQLiteComparisons
          class Equal < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                array = arguments.map { | arg | "\"#{arg}\"" }.join(",")
                { attribute => "[#{array}]" }
              end

              private

              def common_filter_method(attribute, argument)
                { attribute => argument }
              end

            end
          end
        end
      end
    end
  end
end