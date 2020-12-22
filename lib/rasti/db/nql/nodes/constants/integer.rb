module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Integer < Base

            def value
              text_value.to_i
            end

          end
        end
      end
    end
  end
end