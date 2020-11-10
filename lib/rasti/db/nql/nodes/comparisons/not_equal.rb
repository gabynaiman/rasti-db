module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotEqual < Base

            def filter_basic_attribute(collection_class)
              Sequel.negate(attribute.identifier(collection_class) => argument.value)
            end

            def filter_array_attribute(collection_class)
              array_strategy.filter_not_equal attribute.identifier(collection_class), argument.value
            end

          end
        end
      end
    end
  end
end