module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class LiteralString < Treetop::Runtime::SyntaxNode

            def value
              string.text_value
            end

          end
        end
      end
    end
  end
end