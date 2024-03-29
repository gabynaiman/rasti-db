module Rasti
  module DB
    class Query

      DATASET_CHAINED_METHODS = [:where, :exclude, :or, :order, :reverse_order, :limit, :offset].freeze

      include Enumerable

      def initialize(environment:, collection_class:, dataset:, relations_graph:nil)
        @environment = environment
        @collection_class = collection_class
        @dataset = dataset.qualify collection_class.collection_name
        @relations_graph = relations_graph || Relations::Graph.new(environment, collection_class)
      end

      DATASET_CHAINED_METHODS.each do |method|
        define_method method do |*args, &block|
          build_query dataset: dataset.public_send(method, *args, &block)
        end
      end

      def raw
        dataset.all
      end

      def pluck(*attributes)
        ds = dataset.select(*attributes.map { |a| Sequel[collection_class.collection_name][a] })
        attributes.count == 1 ? ds.map { |r| r[attributes.first] } : ds.map(&:values)
      end

      def primary_keys
        pluck collection_class.primary_key
      end

      def select_attributes(*attributes)
        build_query dataset: dataset.select(*attributes.map { |a| Sequel[collection_class.collection_name][a] })
      end

      def exclude_attributes(*excluded_attributes)
        attributes = collection_class.collection_attributes - excluded_attributes
        select_attributes(*attributes)
      end

      def all_attributes
        build_query dataset: dataset.select_all(collection_class.collection_name)
      end

      def select_graph_attributes(selected_attributes)
        build_query relations_graph: relations_graph.merge(selected_attributes: selected_attributes)
      end

      def exclude_graph_attributes(excluded_attributes)
        build_query relations_graph: relations_graph.merge(excluded_attributes: excluded_attributes)
      end

      def graph_queries(queries)
        build_query relations_graph: relations_graph.merge(queries: queries)
      end

      def all_graph_attributes(*relations)
        build_query relations_graph: relations_graph.with_all_attributes_for(relations)
      end

      def select_computed_attributes(*computed_attributes)
        ds = computed_attributes.inject(dataset) do |inner_ds, name|
          computed_attribute = collection_class.computed_attributes[name]
          computed_attribute.apply_join(inner_ds, environment).select_append(computed_attribute.identifier.as(name))
        end
        build_query dataset: ds
      end

      def all
        build_models dataset.all
      end
      alias_method :to_a, :all

      def each(batch_size:nil, &block)
        if batch_size.nil?
          all.each(&block)
        else
          each_batch(size: batch_size) do |models|
            models.each { |model| block.call model }
          end
        end
      end

      def each_batch(size:, &block)
        primary_keys.each_slice(size) do |pks|
          query = where(collection_class.primary_key => pks)
          block.call query.all
        end
      end

      def graph(*relations)
        build_query relations_graph: relations_graph.merge(relations: relations)
      end

      def join(*relations)
        graph = Relations::Graph.new environment, collection_class, relations

        ds = graph.add_joins(dataset).distinct

        build_query dataset: ds
      end

      def count
        dataset.count
      end

      def any?
        count > 0
      end

      def empty?
        !any?
      end

      def first
        build_model dataset.first
      end

      def last
        build_model dataset.last
      end

      def detect(*args, &block)
        where(*args, &block).first
      end

      def to_s
        "#<#{self.class.name}: \"#{dataset.sql}\">"
      end
      alias_method :inspect, :to_s

      def nql(filter_expression)
        sentence = nql_parser.parse filter_expression

        raise NQL::InvalidExpressionError.new(filter_expression) if sentence.nil?

        ds = sentence.computed_attributes(collection_class).inject(dataset) do |inner_ds, name|
          collection_class.computed_attributes[name].apply_join inner_ds, environment
        end
        query = build_query dataset: ds

        dependency_tables = sentence.dependency_tables
        query = query.join(*dependency_tables) unless dependency_tables.empty?

        query.where sentence.filter_condition(collection_class)
      end

      private

      attr_reader :environment, :collection_class, :dataset, :relations_graph

      def build_query(**args)
        current_args = {
          environment: environment,
          collection_class: collection_class,
          dataset: dataset,
          relations_graph: relations_graph
        }

        Query.new(**current_args.merge(args))
      end

      def build_model(row)
        row ? build_models([row]).first : nil
      end

      def build_models(rows)
        with_graph(rows).map do |row|
          collection_class.model.new slice_defined_attributes(row)
        end
      end

      def slice_defined_attributes(row)
        row.select { |k,_| defined_attributes.include? k }
      end

      def defined_attributes
        @defined_attributes ||= collection_class.model.attribute_names.to_set
      end

      def chainable(&block)
        build_query dataset: instance_eval(&block)
      end

      def with_related(relation_name, primary_keys)
        ds = collection_class.relations[relation_name].apply_filter environment, dataset, primary_keys
        build_query dataset: ds
      end

      def with_graph(data)
        rows = data.is_a?(Array) ? data : [data]
        relations_graph.fetch_graph rows
        data
      end

      def qualify(collection_name, data_source_name: nil)
        data_source_name ||= collection_class.data_source_name
        environment.qualify data_source_name, collection_name
      end

      def nql_parser
        NQL::SyntaxParser.new
      end

      def method_missing(method, *args, &block)
        if collection_class.queries.key? method
          instance_exec(*args, &collection_class.queries.fetch(method))
        else
          super
        end
      end

      def respond_to_missing?(method, include_private=false)
        collection_class.queries.key?(method) || super
      end

    end
  end
end
