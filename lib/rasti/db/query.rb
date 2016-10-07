module Rasti
  module DB
    class Query

      CHAINED_METHODS = [:where, :exclude, :and, :or, :order, :reverse_order, :limit, :offset].freeze

      include Enumerable

      def initialize(collection_class, dataset, relations=[], schema=nil)
        @collection_class = collection_class
        @dataset = dataset
        @relations = relations
        @schema = schema
      end

      CHAINED_METHODS.each do |method|
        define_method method do |*args, &block|
          Query.new collection_class, 
                    dataset.send(method, *args, &block), 
                    relations, 
                    schema
        end
      end

      def all
        with_relations(dataset.all).map do |row| 
          collection_class.model.new row
        end
      end

      def each(&block)
        all.each &block
      end

      def count
        dataset.count
      end

      def first
        instance = with_relations dataset.first
        instance ? collection_class.model.new(instance) : nil
      end

      def last
        instance = with_relations dataset.last
        instance ? collection_class.model.new(instance) : nil
      end

      def graph(*rels)
        Query.new collection_class, 
                  dataset, 
                  (relations | rels), 
                  schema
      end

      def to_s
        "#<#{self.class.name}: \"#{dataset.sql}\">"
      end
      alias_method :inspect, :to_s

      private

      def chainable(&block)
        ds = instance_eval &block
        Query.new collection_class, ds, schema
      end

      def with_relations(data)
        rows = data.is_a?(Array) ? data : [data]
        Relations.graph_to rows, relations, collection_class, dataset.db, schema
        data
      end

      def with_schema(identifier)
        Sequel.qualify schema, identifier
      end

      def method_missing(method, *args, &block)
        if collection_class.queries.key?(method)
          instance_exec *args, &collection_class.queries[method]
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