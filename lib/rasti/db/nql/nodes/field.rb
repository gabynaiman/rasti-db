module Rasti
  module DB
    module NQL
      module Nodes
        class Field < Treetop::Runtime::SyntaxNode

          def to_filter
            tables.empty? ? Sequel[column.to_sym] : Sequel[tables.join('__').to_sym][column.to_sym]
          end

          def tables
            _tables.elements.map{ |e| e.table.text_value }
          end

          def column
            _column.text_value
          end

        end
      end
    end
  end
end