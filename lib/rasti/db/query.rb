module Rasti
  module DB
    class Query

      DATASET_CHAINED_METHODS = [:where, :exclude, :or, :order, :reverse_order, :limit, :offset].freeze

      include Enumerable
      include Helpers::WithSchema

      def initialize(collection_class:, dataset:, relations_graph:nil, schema:nil)
        @collection_class = collection_class
        @dataset = dataset
        @relations_graph = relations_graph || Relations::Graph.new(dataset.db, schema)
        @schema = schema
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

      def all
        with_graph(dataset.all).map do |row| 
          collection_class.model.new row
        end
      end
      alias_method :to_a, :all

      def each(&block)
        all.each(&block)
      end

      def graph(*relations)
        build_query relations_graph: relations_graph.merge(relations)
      end

      def join(*relations)
        graph = Relations::Graph.new dataset.db, schema, relations
        
        ds = graph.add_joins(dataset, collection_class)
                  .distinct
                  .select_all(collection_class.collection_name)
        
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
        row = dataset.first
        row ? collection_class.model.new(with_graph(row)) : nil
      end

      def last
        row = dataset.last
        row ? collection_class.model.new(with_graph(row)) : nil
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

        dependency_tables = sentence.dependency_tables
        query = dependency_tables.empty? ? self : join(*dependency_tables)
        
        query.where sentence.filter_condition
      end

      private

      attr_reader :collection_class, :dataset, :relations_graph, :schema

      def build_query(**args)
        current_args = {
          collection_class: collection_class,
          dataset: dataset,
          relations_graph: relations_graph,
          schema: schema
        }

        Query.new(**current_args.merge(args))
      end

      def chainable(&block)
        build_query dataset: instance_eval(&block)
      end

      def with_related(relation_name, primary_keys)
        ds = collection_class.relations[relation_name].apply_filter dataset, schema, primary_keys
        build_query dataset: ds
      end

      def with_graph(data)
        rows = data.is_a?(Array) ? data : [data]
        relations_graph.fetch_graph rows, collection_class
        data
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