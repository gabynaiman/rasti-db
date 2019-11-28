module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class GreaterThanOrEqual < Base

            def filter_condition
              field.identifier >= argument.value
            end

          end
        end
      end
    end
  end
end