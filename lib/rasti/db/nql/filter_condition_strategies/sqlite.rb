module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class SQLite < Base

          SQLITE_TYPES = {
            array: Types::SQLiteArray
          }

          private

          def type_for(argument)
            SQLITE_TYPES.fetch(argument.type, Types::Generic)
          end

        end
      end
    end
  end
end