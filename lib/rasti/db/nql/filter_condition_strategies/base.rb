module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class Base

          def filter_include(attribute, argument)
            filter_as comparison_module::Include, attribute, argument
          end

          def filter_equal(attribute, argument)
            filter_as comparison_module::Equal, attribute, argument
          end

          def filter_not_include(attribute, argument)
            filter_as comparison_module::NotInclude, attribute, argument
          end

          def filter_not_equal(attribute, argument)
            filter_as comparison_module::NotEqual, attribute, argument
          end

          def filter_like(attribute, argument)
            filter_as comparison_module::Like, attribute, argument
          end

          def filter_greater_than(attribute, argument)
            filter_as comparison_module::GreaterThan, attribute, argument
          end

          def filter_greater_than_or_equal(attribute, argument)
            filter_as comparison_module::GreaterThanOrEqual, attribute, argument
          end

          def filter_less_than(attribute, argument)
            filter_as comparison_module::LessThan, attribute, argument
          end

          def filter_less_than_or_equal(attribute, argument)
            filter_as comparison_module::LessThanOrEqual, attribute, argument
          end

          def for_comparison_include(attribute, argument)
            filter_as comparison_module::Include, attribute, argument
          end

          private

          def filter_as(comparison, attribute, argument)
            comparison.public_send method_for(argument), attribute, argument.value
          end

          def method_for(argument)
            "for_#{argument.type}".to_sym
          end

        end
      end
    end
  end
end