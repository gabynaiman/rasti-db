module Rasti
  module DB
    class TypeConverter

      CONVERTIONS = {
        postgres: {
          /^json$/         => ->(value, match) { Sequel.pg_json value },
          /^hstore$/       => ->(value, match) { Sequel.hstore value },
          /^hstore\[\]$/   => ->(value, match) { Sequel.pg_array value.map { |v| Sequel.hstore v }, 'hstore' },
          /^([a-z]+)\[\]$/ => ->(value, match) { Sequel.pg_array value, match.captures[0] }
        }
      }

      def initialize(db, collection_name)
        @db = db
        @collection_name = collection_name
      end

      def apply_to(attributes)
        convertions = self.class.convertions_for @db, @collection_name

        return attributes if convertions.empty?

        (attributes.is_a?(Array) ? attributes : [attributes]).each do |attrs|
          convertions.each do |name, convertion|
            attrs[name] = convertion[:block].call attrs[name], convertion[:match] if attrs.key? name
          end
        end

        attributes
      end

      @cache ||= {}

      def self.convertions_for(db, collection_name)
        key = [db.database_type, collection_name]
        if !@cache.key?(key)
          columns = Hash[db.schema(collection_name)]
          @cache[key] = columns.each_with_object({}) do |(name, schema), hash| 
            CONVERTIONS.fetch(db.database_type, {}).each do |type, convertion|
              if !hash.key?(name) && match = type.match(schema[:db_type])
                hash[name] = {match: match, block: convertion}
              end
            end
          end
        end
        @cache[key]
      end

    end
  end
end