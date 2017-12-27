module Rasti
  module DB
    module Relations
      class OneToMany < Base

        def foreign_key
          @foreign_key ||= options[:foreign_key] || source_collection_class.foreign_key
        end

        def graph_to(rows, db, schema=nil, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }.uniq

          target_collection = target_collection_class.new db, schema

          relation_rows = target_collection.where(foreign_key => pks)
                                           .graph(*relations)
                                           .group_by { |r| r.public_send(foreign_key) }

          rows.each do |row| 
            row[name] = build_graph_result relation_rows.fetch(row[source_collection_class.primary_key], [])
          end
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          target_name = qualified_target_collection_name schema

          dataset.join(target_name, foreign_key => source_collection_class.primary_key)
                 .where(Sequel.qualify(target_name, target_collection_class.primary_key) => primary_keys)
                 .select_all(qualified_source_collection_name(schema))
                 .distinct
        end

        private

        def build_graph_result(rows)
          rows
        end

      end
    end
  end
end