module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class False < Treetop::Runtime::SyntaxNode

            def value
              false
            end

          end
        end
      end
    end
  end
end