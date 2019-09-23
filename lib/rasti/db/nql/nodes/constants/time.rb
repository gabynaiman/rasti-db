module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Time < Treetop::Runtime::SyntaxNode

            def value
              Timing::TimeInZone.parse text_value
            end

          end
        end
      end
    end
  end
end