module Rasti
  module DB
    module NQL
      module Nodes
        class ArrayContent < Treetop::Runtime::SyntaxNode

          def values
            [left.value] + right_value
          end

          private

          def right_value
            right.is_a?(self.class) ? right.values : [right.value]
          end

        end
      end
    end
  end
end