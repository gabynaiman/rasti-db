module Rasti
  module DB
    module Relations
      class Graph

        def initialize(environment, collection_class, relations=[], selected_attributes={}, excluded_attributes={}, sub_queries={})
          @environment = environment
          @collection_class = collection_class
          @graph = build_graph relations,
                               Hash::Indifferent.new(selected_attributes),
                               Hash::Indifferent.new(excluded_attributes),
                               Hash::Indifferent.new(sub_queries)
        end

        def merge(relations:[], selected_attributes:{}, excluded_attributes:{}, sub_queries: {})
          Graph.new environment,
                    collection_class,
                    (flat_relations | relations),
                    flat_selected_attributes.merge(selected_attributes),
                    flat_excluded_attributes.merge(excluded_attributes),
                    flat_sub_queries.merge(sub_queries)
        end

        def with_all_attributes_for(relations)
          relations_with_all_attributes = relations.map { |r| [r, nil] }.to_h

          merge selected_attributes: relations_with_all_attributes,
                excluded_attributes: relations_with_all_attributes
        end

        def apply_to(query)
          query.graph(*flat_relations)
               .select_graph_attributes(flat_selected_attributes)
               .exclude_graph_attributes(flat_excluded_attributes)
               .with_sub_queries(flat_sub_queries)
        end

        def fetch_graph(rows)
          return if rows.empty?
          graph.roots.each do |node|
            relation_of(node).fetch_graph environment,
                                          rows,
                                          node[:selected_attributes],
                                          node[:excluded_attributes],
                                          node[:sub_queries] ,
                                          subgraph_of(node)
          end
        end

        def add_joins(dataset, prefix=nil)
          graph.roots.inject(dataset) do |ds, node|
            relation = relation_of node
            dataset_with_relation = relation.add_join environment, ds, prefix
            subgraph_of(node).add_joins dataset_with_relation, relation.join_relation_name(prefix)
          end
        end

        private

        attr_reader :environment, :collection_class, :graph

        def relation_of(node)
          collection_class.relations.fetch(node[:name])
        end

        def flat_relations
          graph.map(&:id)
        end

        def flat_selected_attributes
          graph.each_with_object(Hash::Indifferent.new) do |node, hash|
            hash[node.id] = node[:selected_attributes]
          end
        end

        def flat_excluded_attributes
          graph.each_with_object(Hash::Indifferent.new) do |node, hash|
            hash[node.id] = node[:excluded_attributes]
          end
        end

        def flat_sub_queries
          graph.each_with_object(Hash::Indifferent.new) do |node, hash|
            hash[node.id] = node[:sub_queries]
          end
        end

        def subgraph_of(node)
          relations = []
          selected = Hash::Indifferent.new
          excluded = Hash::Indifferent.new
          sub_queries = Hash::Indifferent.new

          node.descendants.each do |descendant|
            id = descendant.id[node[:name].length+1..-1]
            relations << id
            selected[id] = descendant[:selected_attributes]
            excluded[id] = descendant[:excluded_attributes]
            sub_queries[id] = descendant[:sub_queries]
          end

          Graph.new environment,
                    relation_of(node).target_collection_class,
                    relations,
                    selected,
                    excluded,
                    sub_queries
        end

        def build_graph(relations, selected_attributes, excluded_attributes, sub_queries)
          HierarchicalGraph.new.tap do |graph|
            flatten(relations).each do |relation|
              sections = relation.split('.')

              graph.add_node relation, name: sections.last.to_sym,
                                       selected_attributes: selected_attributes[relation],
                                       excluded_attributes: excluded_attributes[relation],
                                       sub_queries: sub_queries[relation]

              if sections.count > 1
                parent_id = sections[0..-2].join('.')
                graph.add_relation parent_id: parent_id,
                                   child_id: relation
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
