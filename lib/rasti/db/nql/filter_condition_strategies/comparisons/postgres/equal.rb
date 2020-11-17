module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class Equal < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                Sequel.&(
                  Sequel.pg_array(attribute).contains(Sequel.pg_array(arguments)),
                  Sequel.pg_array(attribute).contained_by(Sequel.pg_array(arguments))
                )
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