module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Array < Base

            def value
              contents.is_a?(ArrayContent) ? contents.values : [contents.value]
            end

          end
        end
      end
    end
  end
end