module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class Postgres < Base

          private

          def comparison_module
            PostgresComparisons
          end

        end
      end
    end
  end
end