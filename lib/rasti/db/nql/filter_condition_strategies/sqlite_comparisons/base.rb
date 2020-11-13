module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module SQLiteComparisons

          class TypedComparisonNotSupported < StandardError

            attr_reader :comparison, :type

            def initialize(comparison, type)
              @comparison = comparison
              @type = type
              super "Compare by #{comparison} have no support when filter #{type} with this filter condition strategy"
            end

          end

          class Base
            class << self

              TYPE_METHODS = [
                :for_array,
                :for_false,
                :for_float,
                :for_integer,
                :for_literalstring,
                :for_string,
                :for_time,
                :for_true
              ]

              TYPE_METHODS.each do |method|
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