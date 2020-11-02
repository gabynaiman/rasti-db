module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Include < Base

            def filter_condition(collection_class)
              Sequel.ilike(attribute.identifier(collection_class), "%#{argument.value}%")
            end

          end
        end
      end
    end
  end
end