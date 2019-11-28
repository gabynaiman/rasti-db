module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class LessThan < Base

            def to_filter
              left.to_filter < right.value
            end

          end
        end
      end
    end
  end
end