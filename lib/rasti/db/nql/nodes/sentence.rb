module Rasti
  module DB
    module NQL
      module Nodes
        class Sentence < Treetop::Runtime::SyntaxNode

          def dependency_tables
            proposition.dependency_tables
          end

          def filter_condition
            proposition.filter_condition
          end

        end
      end
    end
  end
end