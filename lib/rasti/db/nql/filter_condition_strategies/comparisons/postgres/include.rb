module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class Include < Base
            class << self

              def for_array(attribute, arguments)
                attribute.pg_array.overlaps to_pg_array(arguments)
              end

              private

              def common_filter_method(attribute, argument)
                Sequel.ilike attribute, "%#{argument}%"
              end

            end
          end
        end
      end
    end
  end
end