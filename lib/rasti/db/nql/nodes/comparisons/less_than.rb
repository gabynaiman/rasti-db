module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class LessThan < Base

            def filter_condition(collection_class)
              attribute.identifier(collection_class) < argument.value
            end

          end
        end
      end
    end
  end
end