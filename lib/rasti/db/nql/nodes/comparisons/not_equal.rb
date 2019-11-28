module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotEqual < Base

            def to_filter
              Sequel.negate(left.to_filter => right.value)
            end

          end
        end
      end
    end
  end
end