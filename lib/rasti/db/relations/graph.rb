module Rasti
  module DB
    module Relations
      class Graph

        def initialize(db, schema, collection_class, relations=[], selected_attributes={}, excluded_attributes={})
          @db = db
          @schema = schema
          @collection_class = collection_class
          @graph = build_graph relations
          @selected_attributes = Hash::Indifferent.new(selected_attributes)
          @excluded_attributes = Hash::Indifferent.new(excluded_attributes)
        end

        def merge(relations:[], selected_attributes:{}, excluded_attributes:{})
          Graph.new db, 
                    schema, 
                    collection_class, 
                    (flat_relations | relations), 
                    @selected_attributes.merge(selected_attributes),
                    @excluded_attributes.merge(excluded_attributes)
        end

        def with_all_attributes_for(relations)
          relations_with_all_attributes = relations.map { |r| [r, nil] }.to_h

          merge selected_attributes: relations_with_all_attributes, 
                excluded_attributes: relations_with_all_attributes
        end

        def apply_to(query)
          query.graph(*flat_relations)
               .select_graph_attributes(selected_attributes)
               .exclude_graph_attributes(excluded_attributes)
        end

        def fetch_graph(rows)
          return if rows.empty?

          graph.roots.each do |node|
            relation_of(node).fetch_graph rows, 
                                          db, 
                                          schema, 
                                          selected_attributes[node.id], 
                                          excluded_attributes[node.id], 
                                          subgraph_of(node)
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

        attr_reader :db, :schema, :collection_class, :graph, :selected_attributes, :excluded_attributes

        def relation_of(node)
          collection_class.relations.fetch(node[:name])
        end

        def flat_relations
          graph.map(&:id)
        end

        def subgraph_of(node)
          relations = []
          selected = {}
          excluded = {}

          node.descendants.each do |descendant|
            id = descendant.id[node[:name].length+1..-1]
            relations << id
            selected[id] = selected_attributes[descendant.id]
            excluded[id] = excluded_attributes[descendant.id]
          end

          Graph.new db, 
                    schema, 
                    relation_of(node).target_collection_class, 
                    relations, 
                    selected, 
                    excluded
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