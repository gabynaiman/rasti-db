module Rasti
  module DB
    module Relations
      class ManyToOne < Base

        def foreign_key
          @foreign_key ||= options[:foreign_key] || target_collection_class.foreign_key
        end

        def graph_to(rows, db, schema=nil, relations=[])
          fks = rows.map { |row| row[foreign_key] }.uniq

          target_collection = target_collection_class.new db, schema

          relation_rows = target_collection.where(source_collection_class.primary_key => fks)
                                           .graph(*relations)
                                           .each_with_object({}) do |row, hash| 
                                              hash[row.public_send(source_collection_class.primary_key)] = row
                                            end
          
          rows.each do |row| 
            row[name] = relation_rows[row[foreign_key]]
          end
        end

        def join_to(dataset, schema=nil, prefix=nil)
          relation_alias = join_relation_name prefix

          qualified_relation_source = prefix ? Sequel[prefix] : qualified_source_collection_name(schema)

          relation_condition = {
            Sequel[relation_alias][target_collection_class.primary_key] => qualified_relation_source[foreign_key]
          }

          dataset.join(qualified_target_collection_name(schema).as(relation_alias), relation_condition)
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          dataset.where(foreign_key => primary_keys)
        end

      end
    end
  end
end