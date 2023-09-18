module Rasti
  module DB
    module Relations
      class ManyToOne < Base

        def foreign_key
          @foreign_key ||= options[:foreign_key] || target_collection_class.foreign_key
        end

        def fetch_graph(environment, rows, selected_attributes=nil, excluded_attributes=nil, queries=nil, relations_graph=nil)
          fks = rows.map { |row| row[foreign_key] }.uniq

          target_collection = target_collection_class.new environment

          query = target_collection.where(source_collection_class.primary_key => fks)

          query = query.exclude_attributes(*excluded_attributes) unless excluded_attributes.nil?
          query = query.select_attributes(*selected_attributes) unless selected_attributes.nil?

          query = queries.inject(query) { |new_query, sub_query| new_query.send(sub_query) } unless queries.nil?

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

          relation_name = prefix ? Sequel[prefix] : Sequel[source_collection_class.collection_name]

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => relation_name[foreign_key]
          }

          dataset.join(environment.qualify_collection(target_collection_class).as(relation_alias), relation_condition)
        end

        def apply_filter(environment, dataset, primary_keys)
          dataset.where(foreign_key => primary_keys)
        end

      end
    end
  end
end
