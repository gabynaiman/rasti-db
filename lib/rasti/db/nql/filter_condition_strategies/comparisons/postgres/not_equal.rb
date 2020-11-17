module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class NotEqual < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                ~ Equal.for_array(attribute, arguments)
              end

              private

              def common_filter_method(attribute, argument)
                ~ Equal.common_filter_method(attribute, argument)
              end

            end
          end
        end
      end
    end
  end
end