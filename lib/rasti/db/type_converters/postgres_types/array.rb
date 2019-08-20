module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class Array

          class << self

            def column_type_regex
              /^([a-z]+)\[\]$/
            end

            def to_db(value, sub_type)
              array = sub_type == 'hstore' ? value.map { |v| Sequel.hstore v } : value
              Sequel.pg_array array
            end

            def db_class
              Sequel::Postgres::PGArray
            end

            def from_db(object)
              object.to_a
            end

          end

        end
      end
    end
  end
end