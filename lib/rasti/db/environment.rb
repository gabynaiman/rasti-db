module Rasti
  module DB
    class Environment

      def initialize(repositories)
        @repositories = repositories
      end

      def repository(name)
        raise "Undefined repository #{name}" unless repositories.key? name
        repositories[name]
      end

      def repository_of(collection_class)
        repository collection_class.repository_name
      end

      def qualify(repository_name, *names)
        repository(repository_name).qualify(*names)
      end

      def qualify_collection(collection_class)
        repository_of(collection_class).qualify(collection_class.collection_name)
      end

      private

      attr_reader :repositories

    end
  end
end