module Rasti
  module DB
    module NQL
      module Nodes
        class ParenthesisSentence < Treetop::Runtime::SyntaxNode
        
          def dependency_tables
            sentence.dependency_tables
          end

          def computed_fields
            sentence.computed_fields
          end

          def filter_condition
            sentence.filter_condition
          end

        end
      end
    end
  end
end