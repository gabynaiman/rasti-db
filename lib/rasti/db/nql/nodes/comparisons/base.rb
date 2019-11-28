module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Base < Treetop::Runtime::SyntaxNode

            def dependency_tables
              left.tables.empty? ? [] : [left.tables.join('.')]
            end

          end
        end
      end
    end
  end
end