module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class NotInclude < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                ~ Include.for_array(attribute, arguments)
              end

              private

              def common_filter_method(attribute, argument)
                ~ Include.common_filter_method(attribute, argument)
              end

            end
          end
        end
      end
    end
  end
end