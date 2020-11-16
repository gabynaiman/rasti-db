module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class Equal < Base
            class << self

              def for_array(attribute, arguments)
                common_filter_method attribute.pg_array, to_pg_array(arguments)
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