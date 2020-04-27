module Rasti
  module DB
    class DataSource

      attr_reader :db, :schema

      def initialize(db, schema=nil)
        @db = db
        @schema = schema
      end

      def qualify(*names)
        ([schema] + names).compact.inject(Sequel) do |scope, name| 
          scope[name.to_sym]
        end
      end
      
    end
  end
end