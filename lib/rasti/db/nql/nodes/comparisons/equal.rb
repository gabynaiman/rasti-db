module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Equal < Base

            def to_filter
              { left.to_filter => right.value }
            end

          end
        end
      end
    end
  end
end