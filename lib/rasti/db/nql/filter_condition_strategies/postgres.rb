module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class Postgres < Base

          PG_TYPES = {
            array: Types::PGArray
          }

          private

          def type_for(argument)
            PG_TYPES.fetch(argument.type, Types::Generic)
          end

        end
      end
    end
  end
end