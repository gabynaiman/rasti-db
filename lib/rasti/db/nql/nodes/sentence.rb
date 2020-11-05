module Rasti
  module DB
    module NQL
      module Nodes
        class Sentence < Treetop::Runtime::SyntaxNode

          def dependency_tables
            proposition.dependency_tables
          end

          def computed_attributes(collection_class)
            proposition.computed_attributes collection_class
          end

          def filter_condition(collection_class)
            proposition.filter_condition collection_class
          end

        end
      end
    end
  end
end