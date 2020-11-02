module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotEqual < Base

            def filter_condition(collection_class)
              Sequel.negate(attribute.identifier(collection_class) => argument.value)
            end

          end
        end
      end
    end
  end
end