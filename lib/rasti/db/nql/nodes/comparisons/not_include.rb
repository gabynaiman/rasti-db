module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class NotInclude < Base

            def filter_condition(collection_class)
              DB.nql_filter_condition_strategy.filter_not_include attribute.identifier(collection_class), argument
            end

          end
        end
      end
    end
  end
end