module Rasti
  module DB
    class Environment

      def initialize(data_sources)
        @data_sources = data_sources
      end

      def data_source(name)
        raise "Undefined data source #{name}" unless data_sources.key? name
        data_sources[name]
      end

      def data_source_of(collection_class)
        data_source collection_class.data_source_name
      end

      def qualify(data_source_name, collection_name)
        data_source(data_source_name).qualify collection_name
      end

      def qualify_collection(collection_class)
        data_source_of(collection_class).qualify collection_class.collection_name
      end

      private

      attr_reader :data_sources

    end
  end
end