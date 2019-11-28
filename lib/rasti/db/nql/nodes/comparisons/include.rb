module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Include < Base

            def to_filter
              Sequel.ilike(field.identifier, "%#{argument.value}%")
            end

          end
        end
      end
    end
  end
end