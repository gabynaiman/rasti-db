module Rasti
  module DB
    module NQL
      module Nodes
        class BinaryNode < Treetop::Runtime::SyntaxNode
          
          def dependency_tables
            values.flat_map(&:dependency_tables)
          end

          def computed_attributes
            left.computed_attributes + right.computed_attributes
          end

          def values
            @values ||= values_for(left) + values_for(right)
          end

          private

          def values_for(node)
            node.class == self.class ? node.values : [node]
          end

        end
      end
    end
  end
end