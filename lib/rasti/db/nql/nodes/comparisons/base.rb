module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Base < Treetop::Runtime::SyntaxNode

            def dependency_tables
              attribute.tables.empty? ? [] : [attribute.tables.join('.')]
            end

            def computed_attributes(collection_class)
              attribute.computed_attributes(collection_class)
            end

          end
        end
      end
    end
  end
end