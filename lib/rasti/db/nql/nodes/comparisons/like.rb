module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Like < Base

            def filter_basic_attribute(collection_class)
              Sequel.ilike(attribute.identifier(collection_class), argument.value)
            end

            def filter_array_attribute(collection_class)
              array_strategy.filter_like attribute.identifier(collection_class), argument.value
            end

          end
        end
      end
    end
  end
end