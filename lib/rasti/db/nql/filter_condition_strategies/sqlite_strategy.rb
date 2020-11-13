module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class SQLiteStrategy < NoneStrategy

          def filter_include(attribute, argument)
            filter_as SQLiteComparisons::Include, attribute, argument
          end

          def filter_equal(attribute, argument)
            filter_as SQLiteComparisons::Equal, attribute, argument
          end

          def filter_not_include(attribute, argument)
            filter_as SQLiteComparisons::NotInclude, attribute, argument
          end

          def filter_not_equal(attribute, argument)
            filter_as SQLiteComparisons::NotEqual, attribute, argument
          end

          def filter_like(attribute, argument)
            filter_as SQLiteComparisons::Like, attribute, argument
          end

          def filter_greather_than(attribute, argument)
            filter_as SQLiteComparisons::GreatherThan, attribute, argument
          end

          def filter_greather_than_or_equal(attribute, argument)
            filter_as SQLiteComparisons::GreatherThanOrEqual, attribute, argument
          end

          def filter_less_than(attribute, argument)
            filter_as SQLiteComparisons::LessThan, attribute, argument
          end

          def filter_less_than_or_equal(attribute, argument)
            filter_as SQLiteComparisons::LessThanOrEqual, attribute, argument
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