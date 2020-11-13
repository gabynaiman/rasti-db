module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Base < Treetop::Runtime::SyntaxNode

            def type
              self.class.name.split('::').last.downcase
            end

          end
        end
      end
    end
  end
end