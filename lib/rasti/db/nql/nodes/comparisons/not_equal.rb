module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotEqual < Base

            def filter_condition
              Sequel.negate(field.identifier => argument.value)
            end

          end
        end
      end
    end
  end
end