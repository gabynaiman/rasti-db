module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class SQLite < Base

          private

          def comparison_module
            SQLiteComparisons
          end

        end
      end
    end
  end
end