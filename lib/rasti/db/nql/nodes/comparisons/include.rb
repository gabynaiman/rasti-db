module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Include < Base

            def filter_condition
              Sequel.ilike(attribute.identifier, "%#{argument.value}%")
            end

          end
        end
      end
    end
  end
end