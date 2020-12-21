module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Array < Base

            def value
              contents.add_values([])
            end

            def add_values(value_array)
              left.add_values(value_array)
              right.add_values(value_array)
            end

          end
        end
      end
    end
  end
end