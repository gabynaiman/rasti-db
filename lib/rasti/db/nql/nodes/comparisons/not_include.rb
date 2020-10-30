module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotInclude < Base

            def filter_condition
              ~ Sequel.ilike(attribute.identifier, "%#{argument.value}%")
            end

          end
        end
      end
    end
  end
end