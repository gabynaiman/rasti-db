module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module SQLiteComparisons
          class Base
            class << self

              FILTER_METHODS = [
                :for_array,
                :for_false,
                :for_float,
                :for_integer,
                :for_literalstring,
                :for_string,
                :for_time,
                :for_true
              ]

              FILTER_METHODS.each do |method|
                define_method method do |*args, &block|
                  common_filter_method *args
                end
              end

              private

              def common_filter_method(attribute, argument)
              end

            end
          end
        end
      end
    end
  end
end