module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Base < Treetop::Runtime::SyntaxNode

            def dependency_tables
              attribute.tables.empty? ? [] : [attribute.tables.join('.')]
            end

            def computed_attributes
              attribute.computed_attributes
            end

          end
        end
      end
    end
  end
end