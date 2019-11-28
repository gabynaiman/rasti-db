module Rasti
  module DB
    module NQL
      module Nodes
        class Conjunction < BinaryNode

          def filter_condition
            Sequel.&(*values.map(&:filter_condition))
          end

        end
      end
    end
  end
end