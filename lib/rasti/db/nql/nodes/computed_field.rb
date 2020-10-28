module Rasti
  module DB
    module NQL
      module Nodes
        class ComputedField < Treetop::Runtime::SyntaxNode

          def identifier
            Sequel[name.text_value.to_sym][:value]
          end

          def computed_fields
            [name.text_value.to_sym]
          end

          def tables
            []
          end

        end
      end
    end
  end
end