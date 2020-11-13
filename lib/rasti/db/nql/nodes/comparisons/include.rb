module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Include < Base

            def filter_condition(collection_class)
              DB.nql_filter_condition_strategy.filter_include attribute.identifier(collection_class), argument
            end

          end
        end
      end
    end
  end
end