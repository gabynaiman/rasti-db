module Rasti
  module DB
    module NQL
      module Nodes
        class Sentence < Treetop::Runtime::SyntaxNode

          def dependency_tables
            proposition.dependency_tables
          end

          def to_filter
            proposition.to_filter
          end

        end
      end
    end
  end
end