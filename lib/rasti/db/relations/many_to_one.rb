module Rasti
  module DB
    module Relations
      class ManyToOne < Base

        def foreign_key
          @foreign_key ||= options[:foreign_key] || target_collection_class.foreign_key
        end

        def fetch_graph(environment, rows, selected_attributes=nil, excluded_attributes=nil, relations_graph=nil)
          fks = rows.map { |row| row[foreign_key] }.uniq

          target_collection = target_collection_class.new environment

          query = target_collection.where(source_collection_class.primary_key => fks)
          query = query.exclude_attributes(*excluded_attributes) if excluded_attributes
          query = query.select_attributes(*selected_attributes) if selected_attributes
          query = relations_graph.apply_to query if relations_graph

          relation_rows = query.each_with_object({}) do |row, hash| 
            hash[row.public_send(source_collection_class.primary_key)] = row
          end
          
          rows.each do |row| 
            row[name] = relation_rows[row[foreign_key]]
          end
        end

        def add_join(environment, dataset, prefix=nil)
          validate_join!
          
          relation_alias = join_relation_name prefix

          qualified_relation_source = prefix ? Sequel[prefix] : qualified_source_collection_name(environment)

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => qualified_relation_source[foreign_key]
          }

          dataset.join(qualified_target_collection_name(environment).as(relation_alias), relation_condition)
        end

        def apply_filter(environment, dataset, primary_keys)
          dataset.where(foreign_key => primary_keys)
        end

      end
    end
  end
end