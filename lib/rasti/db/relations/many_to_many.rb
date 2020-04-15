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

        def qualified_relation_collection_name(schema=nil)
          schema.nil? ? Sequel[relation_collection_name] : Sequel[schema][relation_collection_name]
        end

        def fetch_graph(rows, db, schema=nil, selected_attributes=nil, excluded_attributes=nil, relations_graph=nil)
          pks = rows.map { |row| row[source_collection_class.primary_key] }

          target_collection = target_collection_class.new db, schema

          relation_name = qualified_relation_collection_name schema

          join_rows = target_collection.dataset
                                       .join(relation_name, target_foreign_key => target_collection_class.primary_key)
                                       .where(Sequel[relation_name][source_foreign_key] => pks)
                                       .select_all(target_collection_class.collection_name)
                                       .select_append(Sequel[relation_name][source_foreign_key].as(:source_foreign_key))
                                       .all

          relations_graph.fetch_graph join_rows if relations_graph

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash| 
            attributes = row.select { |attr,_| target_collection_class.model.attributes.include? attr }
            hash[row[:source_foreign_key]] << target_collection_class.model.new(attributes)
          end

          rows.each do |row| 
            row[name] = relation_rows.fetch row[target_collection_class.primary_key], []
          end
        end

        def add_join(dataset, schema=nil, prefix=nil)
          many_to_many_relation_alias = with_prefix prefix, "#{relation_collection_name}_#{SecureRandom.base64}"

          qualified_relation_source = prefix ? Sequel[prefix] : qualified_source_collection_name(schema)

          many_to_many_condition = {
            Sequel[many_to_many_relation_alias][source_foreign_key] => qualified_relation_source[source_collection_class.primary_key]
          }

          relation_alias = join_relation_name prefix

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => Sequel[many_to_many_relation_alias][target_foreign_key]
          }

          dataset.join(qualified_relation_collection_name(schema).as(many_to_many_relation_alias), many_to_many_condition)
                 .join(qualified_target_collection_name(schema).as(relation_alias), relation_condition)
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          relation_name = qualified_relation_collection_name schema

          dataset.join(relation_name, source_foreign_key => target_collection_class.primary_key)
                 .where(Sequel[relation_name][target_foreign_key] => primary_keys)
                 .select_all(source_collection_class.collection_name)
                 .distinct
        end

      end
    end
  end
end