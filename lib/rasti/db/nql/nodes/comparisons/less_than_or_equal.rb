module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class LessThanOrEqual < Base

            def filter_condition(collection_class)
              DB.nql_filter_condition_strategy.filter_less_than_or_equal attribute.identifier(collection_class), argument
            end

          end
        end
      end
    end
  end
end