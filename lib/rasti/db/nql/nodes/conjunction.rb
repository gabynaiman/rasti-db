module Rasti
  module DB
    module NQL
      module Nodes
        class Conjunction < BinaryNode

          def filter_condition(collection_class)
            Sequel.&(*values.map { |value| value.filter_condition(collection_class) } )
          end

        end
      end
    end
  end
end