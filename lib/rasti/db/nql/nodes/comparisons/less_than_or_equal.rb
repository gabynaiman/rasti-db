module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class LessThanOrEqual < Base

            def filter_basic_attribute(collection_class)
              attribute.identifier(collection_class) <= argument.value
            end

            def filter_array_attribute(collection_class)
              array_strategy.filter_less_than_or_equal attribute.identifier(collection_class), argument.value
            end
            
          end
        end
      end
    end
  end
end