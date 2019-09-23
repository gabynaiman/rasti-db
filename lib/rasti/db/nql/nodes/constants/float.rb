module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Float < Treetop::Runtime::SyntaxNode

            def value
              text_value.to_f
            end

          end
        end
      end
    end
  end
end