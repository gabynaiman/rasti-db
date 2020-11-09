module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotInclude < Base

            def filter_condition(collection_class)
              ~ Sequel.ilike(attribute.identifier(collection_class), "%#{argument.value}%")
            end

          end
        end
      end
    end
  end
end