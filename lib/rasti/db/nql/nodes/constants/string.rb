module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class String < Base

            def value
              text_value.strip
            end

          end
        end
      end
    end
  end
end