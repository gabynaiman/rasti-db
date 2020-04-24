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

        def relation_repository_name
          @relation_repository_name ||= options[:relation_repository_name] || source_collection_class.repository_name
        end

        def qualified_relation_collection_name(environment)
          environment.qualify relation_repository_name, relation_collection_name
        end

        def fetch_graph(environment, rows, selected_attributes=nil, excluded_attributes=nil, relations_graph=nil)
          pks = rows.map { |row| row[source_collection_class.primary_key] }

          if target_collection_class.repository_name == relation_repository_name
            target_repository = environment.repository_of target_collection_class
            
            relation_name = qualified_relation_collection_name environment

            join_rows = target_repository.db.from(qualified_target_collection_name(environment))
                                            .join(relation_name, target_foreign_key => target_collection_class.primary_key)
                                            .where(Sequel[relation_name][source_foreign_key] => pks)
                                            .select_all(target_collection_class.collection_name)
                                            .select_append(Sequel[relation_name][source_foreign_key].as(:source_foreign_key))
                                            .all
          else
            relation_repository = environment.repository relation_repository_name

            relation_index = relation_repository.db.from(relation_repository.qualify(relation_collection_name))
                                                   .where(source_foreign_key => pks)
                                                   .select_hash_groups(target_foreign_key, source_foreign_key)

            target_collection = target_collection_class.new environment

            join_rows = target_collection.where(target_collection_class.primary_key => relation_index.keys).raw.flat_map do |row|
              relation_index[row[target_collection_class.primary_key]].map do |source_primary_key|
                row.merge(source_foreign_key: source_primary_key)
              end
            end
          end

          relations_graph.fetch_graph join_rows if relations_graph

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash| 
            attributes = row.select { |attr,_| target_collection_class.model.attributes.include? attr }
            hash[row[:source_foreign_key]] << target_collection_class.model.new(attributes)
          end

          rows.each do |row| 
            row[name] = relation_rows.fetch row[source_collection_class.primary_key], []
          end
        end

        def add_join(environment, dataset, prefix=nil)
          validate_join!
          
          many_to_many_relation_alias = with_prefix prefix, "#{relation_collection_name}_#{SecureRandom.base64}"

          qualified_relation_source = prefix ? Sequel[prefix] : qualified_source_collection_name(environment)

          many_to_many_condition = {
            Sequel[many_to_many_relation_alias][source_foreign_key] => qualified_relation_source[source_collection_class.primary_key]
          }

          relation_alias = join_relation_name prefix

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => Sequel[many_to_many_relation_alias][target_foreign_key]
          }

          dataset.join(qualified_relation_collection_name(environment).as(many_to_many_relation_alias), many_to_many_condition)
                 .join(qualified_target_collection_name(environment).as(relation_alias), relation_condition)
        end

        def apply_filter(environment, dataset, primary_keys)
          relation_name = qualified_relation_collection_name environment

          dataset.join(relation_name, source_foreign_key => target_collection_class.primary_key)
                 .where(Sequel[relation_name][target_foreign_key] => primary_keys)
                 .select_all(source_collection_class.collection_name)
                 .distinct
        end

      end
    end
  end
end