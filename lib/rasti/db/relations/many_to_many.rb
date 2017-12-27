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
          schema.nil? ? relation_collection_name : Sequel.qualify(schema, relation_collection_name)
        end

        def graph_to(rows, db, schema=nil, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }

          target_collection = target_collection_class.new db, schema

          relation_name = qualified_relation_collection_name schema

          join_rows = target_collection.dataset
                                       .join(relation_name, target_foreign_key => target_collection_class.primary_key)
                                       .where(Sequel.qualify(relation_name, source_foreign_key) => pks)
                                       .select_all(qualified_target_collection_name(schema))
                                       .select_append(Sequel.qualify(relation_name, source_foreign_key).as(:source_foreign_key))
                                       .all

          GraphBuilder.graph_to join_rows, relations, target_collection_class, db, schema

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash| 
            attributes = row.select { |attr,_| target_collection_class.model.attributes.include? attr }
            hash[row[:source_foreign_key]] << target_collection_class.model.new(attributes)
          end

          rows.each do |row| 
            row[name] = relation_rows.fetch row[target_collection_class.primary_key], []
          end
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          relation_name = qualified_relation_collection_name schema

          dataset.join(relation_name, source_foreign_key => target_collection_class.primary_key)
                 .where(Sequel.qualify(relation_name, target_foreign_key) => primary_keys)
                 .select_all(qualified_source_collection_name(schema))
                 .distinct
        end

      end
    end
  end
end