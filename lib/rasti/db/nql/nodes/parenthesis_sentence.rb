module Rasti
  module DB
    module NQL
      module Nodes
        class ParenthesisSentence < Treetop::Runtime::SyntaxNode

          def dependency_tables
            sentence.dependency_tables
          end

          def computed_attributes(collection_class)
            sentence.computed_attributes(collection_class)
          end

          def filter_condition(collection_class)
            sentence.filter_condition collection_class
          end

        end
      end
    end
  end
end