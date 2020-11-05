module Rasti
  module DB
    module NQL
      module Nodes
        class Attribute < Treetop::Runtime::SyntaxNode

          def identifier(collection_class)
            if is_computed?(collection_class)
              collection_class.computed_attributes[column].identifier
            else
              tables.empty? ? Sequel[column] : Sequel[tables.join('__').to_sym][column]
            end
          end

          def tables
            _tables.elements.map{ |e| e.table.text_value }
          end

          def column
            _column.text_value.to_sym
          end

          def computed_attributes(collection_class)
            is_computed?(collection_class) ? [column] : []
          end

          private


          def is_computed?(collection_class)
            collection_class.computed_attributes.key? column
          end

        end
      end
    end
  end
end