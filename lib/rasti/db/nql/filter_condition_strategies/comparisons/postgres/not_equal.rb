module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class NotEqual < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                Sequel.negate Sequel.pg_array(attribute) => Sequel.pg_array(arguments)
              end

              private

              def common_filter_method(attribute, argument)
                Sequel.negate attribute => argument
              end

            end
          end
        end
      end
    end
  end
end