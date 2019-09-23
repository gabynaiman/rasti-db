module Rasti
  module DB
    module NQL
      module Nodes
        class Field < Treetop::Runtime::SyntaxNode

          def tables
            _tables.elements.map{ |e| e.table.text_value }
          end

          def name
            _name.text_value
          end

        end
      end
    end
  end
end