module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Base < Treetop::Runtime::SyntaxNode

            def filter_condition_for(comparison, collection_class)
              comparison.filter_basic_attribute collection_class
            end

          end
        end
      end
    end
  end
end