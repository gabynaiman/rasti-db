module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class True < Treetop::Runtime::SyntaxNode

            def value
              true
            end

          end
        end
      end
    end
  end
end