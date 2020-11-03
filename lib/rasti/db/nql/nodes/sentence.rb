module Rasti
  module DB
    module NQL
      module Nodes
        class Sentence < Treetop::Runtime::SyntaxNode

          def dependency_tables
            proposition.dependency_tables
          end

          def computed_attributes
            proposition.computed_attributes
          end

          def filter_condition(collection_class)
            proposition.filter_condition collection_class
          end

        end
      end
    end
  end
end