module Rasti
  module DB
    class DataSource

      attr_reader :db, :schema

      def initialize(db, schema=nil)
        @db = db
        @schema = schema ? schema.to_sym : nil
      end

      def qualify(collection_name)
        schema ? Sequel[schema][collection_name] : Sequel[collection_name]
      end
      
    end
  end
end