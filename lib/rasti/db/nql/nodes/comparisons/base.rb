module Rasti
  module DB
    module NQL
      module Nodes
        module Comparisons
          class Base < Treetop::Runtime::SyntaxNode

            def dependency_tables
              attribute.tables.empty? ? [] : [attribute.tables.join('.')]
            end

            def computed_attributes(collection_class)
              attribute.computed_attributes(collection_class)
            end

            def filter_condition(collection_class)
              DB.nql_filter_condition_strategy.public_send "filter_#{comparison_name}", attribute.identifier(collection_class), argument
            end

            private

            def comparison_name
              Inflecto.underscore Inflecto.demodulize(self.class)
            end

          end
        end
      end
    end
  end
end