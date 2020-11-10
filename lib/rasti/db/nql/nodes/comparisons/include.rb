module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Include < Base

            def filter_basic_attribute(collection_class)
              Sequel.ilike(attribute.identifier(collection_class), "%#{argument.value}%")
            end

            def filter_array_attribute(collection_class)
              array_strategy.filter_include attribute.identifier(collection_class), argument.value
            end

          end
        end
      end
    end
  end
end