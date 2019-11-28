module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class GreaterThanOrEqual < Base

            def to_filter
              field.identifier >= argument.value
            end

          end
        end
      end
    end
  end
end