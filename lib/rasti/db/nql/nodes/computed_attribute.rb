module Rasti
  module DB
    module NQL
      module Nodes
        class ComputedAttribute < Treetop::Runtime::SyntaxNode

          def identifier(collection_class)
            collection_class.computed_attributes[computed_attribute].identifier
          end

          def computed_attributes
            [computed_attribute]
          end

          def tables
            []
          end

          private

          def computed_attribute
            name.text_value.to_sym
          end

        end
      end
    end
  end
end