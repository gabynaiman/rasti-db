module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotEqual < Base

            def to_filter
              Sequel.negate(field.identifier => argument.value)
            end

          end
        end
      end
    end
  end
end