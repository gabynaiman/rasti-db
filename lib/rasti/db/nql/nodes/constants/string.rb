module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class String < Treetop::Runtime::SyntaxNode

            def value
              text_value.strip
            end

          end
        end
      end
    end
  end
end