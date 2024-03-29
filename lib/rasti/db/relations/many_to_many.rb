module Rasti
  module DB
    module Relations
      class ManyToMany < Base

        def source_foreign_key
          @source_foreign_key ||= options[:source_foreign_key] || source_collection_class.foreign_key
        end

        def target_foreign_key
          @target_foreign_key ||= options[:target_foreign_key] || target_collection_class.foreign_key
        end

        def relation_collection_name
          @relation_collection_name ||= options[:relation_collection_name] || [source_collection_class.collection_name, target_collection_class.collection_name].sort.join('_').to_sym
        end

        def relation_data_source_name
          @relation_data_source_name ||= options[:relation_data_source_name] || source_collection_class.data_source_name
        end

        def fetch_graph(environment, rows, selected_attributes=nil, excluded_attributes=nil, queries=nil, relations_graph=nil)
          pks = rows.map { |row| row[source_collection_class.primary_key] }
          
          if target_collection_class.data_source_name == relation_data_source_name
            target_data_source = environment.data_source_of target_collection_class

            dataset = target_data_source.db.from(environment.qualify_collection(target_collection_class))
                                           .join(qualified_relation_collection_name(environment), target_foreign_key => target_collection_class.primary_key)
                                           .where(Sequel[relation_collection_name][source_foreign_key] => pks)
                                           .select_all(target_collection_class.collection_name)

            selected_attributes ||= target_collection_class.collection_attributes - excluded_attributes unless excluded_attributes.nil?
            dataset = dataset.select(*selected_attributes.map { |a| Sequel[target_collection_class.collection_name][a] }) unless selected_attributes.nil?

            query = Query.new collection_class: target_collection_class, dataset: dataset, environment: environment
            query = queries.inject(query) { |new_query, sub_query| new_query.send(sub_query) } unless queries.nil?

            join_rows = query.send(:dataset).select_append(Sequel[relation_collection_name][source_foreign_key].as(:source_foreign_key)).all

          else
            relation_data_source = environment.data_source relation_data_source_name

            relation_index = relation_data_source.db.from(relation_data_source.qualify(relation_collection_name))
                                                    .where(source_foreign_key => pks)
                                                    .select_hash_groups(target_foreign_key, source_foreign_key)

            query = target_collection_class.new environment
            query = query.exclude_attributes(*excluded_attributes) unless excluded_attributes.nil?
            query = query.select_attributes(*selected_attributes) unless selected_attributes.nil?

            query = queries.inject(query) { |new_query, sub_query| new_query.send(sub_query) } unless queries.nil?

            join_rows = query.where(target_collection_class.primary_key => relation_index.keys).raw.flat_map do |row|
              relation_index[row[target_collection_class.primary_key]].map do |source_primary_key|
                row.merge(source_foreign_key: source_primary_key)
              end
            end
          end

          relations_graph.fetch_graph join_rows if relations_graph

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash|
            attributes = row.select { |attr,_| target_collection_class.model.attribute_names.include? attr }
            hash[row[:source_foreign_key]] << target_collection_class.model.new(attributes)
          end

          rows.each do |row|
            row[name] = relation_rows.fetch row[source_collection_class.primary_key], []
          end
        end

        def add_join(environment, dataset, prefix=nil)
          validate_join!

          many_to_many_relation_alias = with_prefix prefix, "#{relation_collection_name}_#{SecureRandom.base64}"

          relation_name = prefix ? Sequel[prefix] : Sequel[source_collection_class.collection_name]

          many_to_many_condition = {
            Sequel[many_to_many_relation_alias][source_foreign_key] => relation_name[source_collection_class.primary_key]
          }

          relation_alias = join_relation_name prefix

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => Sequel[many_to_many_relation_alias][target_foreign_key]
          }

          dataset.join(qualified_relation_collection_name(environment).as(many_to_many_relation_alias), many_to_many_condition)
                 .join(environment.qualify_collection(target_collection_class).as(relation_alias), relation_condition)
        end

        def apply_filter(environment, dataset, primary_keys)
          if source_collection_class.data_source_name == relation_data_source_name
            dataset.join(qualified_relation_collection_name(environment), source_foreign_key => source_collection_class.primary_key)
                   .where(Sequel[relation_collection_name][target_foreign_key] => primary_keys)
                   .select_all(source_collection_class.collection_name)
                   .distinct
          else
            data_source = environment.data_source relation_data_source_name
            fks = data_source.db.from(data_source.qualify(relation_collection_name))
                                .where(target_collection_class.foreign_key => primary_keys)
                                .select_map(source_collection_class.foreign_key)
                                .uniq
            dataset.where(source_collection_class.primary_key => fks)
          end
        end

        private

        def qualified_relation_collection_name(environment)
          environment.qualify relation_data_source_name, relation_collection_name
        end

      end
    end
  end
end
