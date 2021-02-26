module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class Array
          class << self

            DB_TYPE_REGEX = /^([a-z]+)\[\]$/

            def to_db?(type)
              !type.match(DB_TYPE_REGEX).nil?
            end

            def to_db(value, type)
              sub_type = type[0..-3]
              array = sub_type == 'hstore' ? value.map { |v| Sequel.hstore v } : value
              Sequel.pg_array array, sub_type
            end

            def from_db?(klass)
              defined?(Sequel::Postgres::PGArray) &&
              klass == Sequel::Postgres::PGArray
            end

            def from_db(value)
              value.to_a
            end

          end
        end
      end
    end
  end
end