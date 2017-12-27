module Rasti
  module DB
    module Relations
      class GraphBuilder
        class << self

          def graph_to(rows, relations, collection_class, db, schema=nil)
            return if rows.empty?

            parse(relations).each do |relation, nested_relations|
              raise "Undefined relation #{relation} for #{collection_class}" unless collection_class.relations.key? relation
              collection_class.relations[relation].graph_to rows, db, schema, nested_relations
            end
          end

          private

          def parse(relations)
            relations.each_with_object({}) do |relation, hash|
              tail = relation.to_s.split '.'
              head = tail.shift.to_sym
              hash[head] ||= []
              hash[head] << tail.join('.') unless tail.empty?
            end
          end

        end
      end
    end
  end
end