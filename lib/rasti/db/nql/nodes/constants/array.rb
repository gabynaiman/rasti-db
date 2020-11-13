module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Array < Base

            def value
              values
            end

            private

            def values
              basic.value.split(',').map(&:strip)
            end

          end
        end
      end
    end
  end
end