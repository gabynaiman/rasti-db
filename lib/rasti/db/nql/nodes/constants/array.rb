module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Array < Treetop::Runtime::SyntaxNode

            def value
              values
            end

            def filter_condition_for(comparison, collection_class)
              comparison.filter_array_attribute collection_class
            end

            private

            def values
              basic.value.split(',').map(&:strip)
            end

          end
        end
      end
    end
  end
end