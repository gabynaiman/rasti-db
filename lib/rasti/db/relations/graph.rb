module Rasti
  module DB
    module Relations
      class Graph

        def initialize(db, schema, collection_class, relations=[])
          @db = db
          @schema = schema
          @collection_class = collection_class
          @graph = build_graph relations
        end

        def merge(relations)
          Graph.new db, schema, collection_class, (flat_relations | relations)
        end

        def apply_to(query)
          query.graph(*flat_relations)
        end

        def fetch_graph(rows)
          return if rows.empty?

          graph.roots.each do |node|
            relation_of(node).fetch_graph rows, db, schema, subgraph_of(node)
          end
        end

        def add_joins(dataset, prefix=nil)
          graph.roots.each do |node|
            relation = relation_of node
            dataset = relation.add_join dataset, schema, prefix
            dataset = subgraph_of(node).add_joins dataset, relation.join_relation_name(prefix)
          end

          dataset
        end

        private

        attr_reader :db, :schema, :collection_class, :graph

        def relation_of(node)
          collection_class.relations.fetch(node[:name])
        end

        def join_alias(node, prefix=nil)
          [prefix, node[:name]].compact.join('__').to_sym
        end

        def flat_relations
          graph.map(&:id)
        end

        def subgraph_of(node)
          relation = collection_class.relations.fetch(node[:name])
          descendants = node.descendants.map { |d| d.id[node[:name].length+1..-1] }
          Graph.new db, schema, relation.target_collection_class, descendants
        end

        def build_graph(relations)
          HierarchicalGraph.new.tap do |graph|
            flatten(relations).each do |relation| 
              sections = relation.split('.')
              graph.add_node relation, name: sections.last.to_sym
              if sections.count > 1
                parent_id = sections[0..-2].join('.')
                graph.add_relation parent_id: parent_id, child_id: relation
              end
            end
          end
        end

        def flatten(relations)
          relations.flat_map do |relation|
            parents = []
            relation.to_s.split('.').map do |section|
              parents << section
              parents.compact.join('.')
            end
          end.uniq.sort
        end

      end
    end
  end
end