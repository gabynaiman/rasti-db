module Rasti
  module DB
    class Query

      CHAINED_METHODS = [:where, :exclude, :and, :or, :order, :reverse_order, :limit, :offset, :distinct].freeze

      include Enumerable

      def initialize(collection_class, dataset)
        @collection_class = collection_class
        @dataset = dataset
      end

      CHAINED_METHODS.each do |method|
        define_method method do |*args, &block|
          Query.new collection_class, dataset.send(method, *args, &block)
        end
      end

      def all
        dataset.all.map { |row| collection_class.model.new row }
      end

      def each(&block)
        all.each(&block)
      end

      def count
        dataset.count
      end

      def first
        instance = dataset.first
        instance ? collection_class.model.new(instance) : nil
      end

      def last
        instance = dataset.last
        instance ? collection_class.model.new(instance) : nil
      end

      def graph(*relations)
        rows = dataset.all

        Relations.graph_to rows, relations, collection_class, dataset.db
        
        rows.map { |row| collection_class.model.new row }
      end

      private

      attr_reader :collection_class, :dataset

    end
  end
end