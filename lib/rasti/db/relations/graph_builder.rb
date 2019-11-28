module Rasti
  module DB
    module Relations
      class GraphBuilder
        class << self

          def graph_to(rows, relations, collection_class, db, schema=nil)
            return if rows.empty?

            parse(relations).each do |relation_name, nested_relations|
              relation = get_relation collection_class, relation_name
              relation.graph_to rows, db, schema, nested_relations
            end
          end

          def joins_to(dataset, relations, collection_class, schema=nil)
            ds = recursive_joins dataset, recursive_parse(relations), collection_class, schema
            qualified_collection_name = schema ? Sequel[schema][collection_class.collection_name] : Sequel[collection_class.collection_name]
            ds.distinct.select_all(qualified_collection_name)
          end

          private

          def get_relation(collection_class, relation_name)
            raise "Undefined relation #{relation_name} for #{collection_class}" unless collection_class.relations.key? relation_name
            collection_class.relations[relation_name]
          end

          def parse(relations)
            relations.each_with_object({}) do |relation, hash|
              tail = relation.to_s.split '.'
              head = tail.shift.to_sym
              hash[head] ||= []
              hash[head] << tail.join('.') unless tail.empty?
            end
          end

          def recursive_parse(relations)
            parse(relations).each_with_object({}) do |(key, value), hash|
              hash[key] = recursive_parse value
            end
          end

          def recursive_joins(dataset, joins, collection_class, schema, prefix=nil)
            joins.each do |relation_name, nested_joins|
              relation = get_relation collection_class, relation_name

              dataset = relation.join_to dataset, schema, prefix

              dataset = recursive_joins dataset, nested_joins, relation.target_collection_class, schema, relation.join_relation_name(prefix) unless nested_joins.empty?
            end

            dataset
          end

        end
      end
    end
  end
end