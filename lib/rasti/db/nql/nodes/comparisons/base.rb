module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Base < Treetop::Runtime::SyntaxNode

            def dependency_tables
              field.tables.empty? ? [] : [field.tables.join('.')]
            end

          end
        end
      end
    end
  end
end