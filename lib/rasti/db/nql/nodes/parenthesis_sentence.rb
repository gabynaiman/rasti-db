module Rasti
  module DB
    module NQL
      module Nodes
        class ParenthesisSentence < Treetop::Runtime::SyntaxNode
        
          def dependency_tables
            sentence.dependency_tables
          end

          def to_filter
            sentence.to_filter
          end

        end
      end
    end
  end
end