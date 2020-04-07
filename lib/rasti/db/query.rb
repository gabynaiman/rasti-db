module Rasti
  module DB
    class Query

      DATASET_CHAINED_METHODS = [:where, :exclude, :or, :order, :reverse_order, :limit, :offset].freeze

      include Enumerable
      include Helpers::WithSchema

      def initialize(collection_class, dataset, relations=[], schema=nil)
        @collection_class = collection_class
        @dataset = dataset
        @relations = relations
        @schema = schema
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
        Query.new collection_class, 
                  dataset.select(*attributes.map { |a| Sequel[collection_class.collection_name][a] }), 
                  relations, 
                  schema
      end

      def exclude_attributes(*excluded_attributes)
        attributes = collection_class.collection_attributes - excluded_attributes
        select_attributes(*attributes)
      end

      def all_attributes
        Query.new collection_class, 
                  dataset.select_all(collection_class.collection_name), 
                  relations, 
                  schema
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

      DATASET_CHAINED_METHODS.each do |method|
        define_method method do |*args, &block|
          Query.new collection_class, 
                    dataset.public_send(method, *args, &block), 
                    relations, 
                    schema
        end
      end

      def graph(*rels)
        Query.new collection_class, 
                  dataset, 
                  (relations | rels), 
                  schema
      end

      def join(*rels)
        Query.new collection_class, 
                  Relations::GraphBuilder.joins_to(dataset, rels, collection_class, schema), 
                  relations, 
                  schema
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

      def chainable(&block)
        ds = instance_eval(&block)
        Query.new collection_class, ds, relations, schema
      end

      def with_related(relation_name, primary_keys)
        ds = collection_class.relations[relation_name].apply_filter dataset, schema, primary_keys
        Query.new collection_class, ds, relations, schema
      end

      def with_graph(data)
        rows = data.is_a?(Array) ? data : [data]
        Relations::GraphBuilder.graph_to rows, relations, collection_class, dataset.db, schema
        data
      end

      def nql_parser
        NQL::SyntaxParser.new
      end

      def method_missing(method, *args, &block)
        if collection_class.queries.key?(method)
          instance_exec(*args, &collection_class.queries[method])
        else
          super
        end
      end

      def respond_to_missing?(method, include_private=false)
        collection_class.queries.key?(method) || super
      end

      attr_reader :collection_class, :dataset, :relations, :schema

    end
  end
end