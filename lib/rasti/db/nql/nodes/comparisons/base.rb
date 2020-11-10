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

            def filter_condition(collection_class)
              argument.filter_condition_for(self, collection_class)
            end

            private

            def array_strategy
              DB.nql_array_strategy
            end

          end
        end
      end
    end
  end
end