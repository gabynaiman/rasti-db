module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class SQLiteStrategy
          class << self

            def filter_include(attribute, argument)
              SQLiteComparisons::Include.public_send method_for(argument), attribute, argument.value
            end

            def filter_equal(attribute, argument)
              SQLiteComparisons::Equal.public_send method_for(argument), attribute, argument.value
            end

            def filter_not_include(attribute, argument)
              SQLiteComparisons::NotInclude.public_send method_for(argument), attribute, argument.value
            end

            def filter_not_equal(attribute, argument)
              SQLiteComparisons::NotEqual.public_send method_for(argument), attribute, argument.value
            end

            def filter_like(attribute, argument)
              SQLiteComparisons::Like.public_send method_for(argument), attribute, argument.value
            end

            def filter_greather_than(attribute, argument)
              SQLiteComparisons::GreatherThan.public_send method_for(argument), attribute, argument.value
            end

            def filter_greather_than_or_equal(attribute, argument)
              SQLiteComparisons::GreatherThanOrEqual.public_send method_for(argument), attribute, argument.value
            end

            def filter_less_than(attribute, argument)
              SQLiteComparisons::LessThan.public_send method_for(argument), attribute, argument.value
            end

            def filter_less_than_or_equal(attribute, argument)
              SQLiteComparisons::LessThanOrEqual.public_send method_for(argument), attribute, argument.value
            end

            private

            def method_for(argument)
              "for_#{argument.type}".to_sym
            end

          end
        end
      end
    end
  end
end