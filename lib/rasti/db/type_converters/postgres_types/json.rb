module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class JSON
          class << self

            DB_TYPE_REGEX = /^json$/

            def to_db?(type)
              !type.match(DB_TYPE_REGEX).nil?
            end

            def to_db(value, type)
              Sequel.pg_json value
            end

            def from_db?(klass)
              to_hash?(klass) || to_array?(klass)
            end

            def from_db(value)
              to_hash?(value.class) ? value.to_h : value.to_a
            end

            private

            def to_hash?(klass)
              defined?(Sequel::Postgres::JSONHash) &&
              klass == Sequel::Postgres::JSONHash
            end

            def to_array?(klass)
              defined?(Sequel::Postgres::JSONArray) &&
              klass == Sequel::Postgres::JSONArray
            end

          end
        end
      end
    end
  end
end