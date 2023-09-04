module Rasti
  module DB
    module Relations
      class OneToMany < Base

        def foreign_key
          @foreign_key ||= options[:foreign_key] || source_collection_class.foreign_key
        end

        def fetch_graph(environment, rows, selected_attributes=nil, excluded_attributes=nil, sub_queries=nil, relations_graph=nil)
          pks = rows.map { |row| row[source_collection_class.primary_key] }.uniq

          target_collection = target_collection_class.new environment

          query = target_collection.where(foreign_key => pks)
          query = query.exclude_attributes(*excluded_attributes) if excluded_attributes
          query = query.select_attributes(*selected_attributes) if selected_attributes

          query = sub_queries.inject(query) { |new_query, sub_query| new_query.execute_subquery(query, sub_query) } if sub_queries

          query = relations_graph.apply_to query if relations_graph

          relation_rows = query.group_by(&foreign_key)

          rows.each do |row|
            row[name] = build_graph_result relation_rows.fetch(row[source_collection_class.primary_key], [])
          end
        end

        def add_join(environment, dataset, prefix=nil)
          validate_join!

          relation_alias = join_relation_name prefix

          relation_name = prefix ? Sequel[prefix] : Sequel[source_collection_class.collection_name]

          relation_condition = {
            Sequel[relation_alias][foreign_key] => relation_name[source_collection_class.primary_key]
          }

          dataset.join(environment.qualify_collection(target_collection_class).as(relation_alias), relation_condition)
        end

        def apply_filter(environment, dataset, primary_keys)
          if source_collection_class.data_source_name == target_collection_class.data_source_name
            dataset.join(environment.qualify_collection(target_collection_class), foreign_key => source_collection_class.primary_key)
                   .where(Sequel[target_collection_class.collection_name][target_collection_class.primary_key] => primary_keys)
                   .select_all(target_collection_class.collection_name)
                   .distinct
          else
            target_collection = target_collection_class.new environment
            fks = target_collection.where(target_collection_class.primary_key => primary_keys)
                                   .pluck(foreign_key)
                                   .uniq
            dataset.where(source_collection_class.primary_key => fks)
          end
        end

        private

        def build_graph_result(rows)
          rows
        end

      end
    end
  end
end
