module Rasti
  module DB
    module NQL
      module Nodes
        class Disjunction < BinaryNode

          def to_filter
            Sequel.|(*values.map(&:to_filter))
          end

        end
      end
    end
  end
end