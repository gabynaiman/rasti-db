module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class JSONB
          class << self

            DB_TYPE_REGEX = /^jsonb$/

            def to_db?(type)
              !type.match(DB_TYPE_REGEX).nil?
            end

            def to_db(value, type)
              Sequel.pg_jsonb value
            end

            def from_db?(klass)
              to_hash?(klass) || to_array?(klass)
            end

            def from_db(value)
              to_hash?(value.class) ? value.to_h : value.to_a
            end

            private

            def to_hash?(klass)
              defined?(Sequel::Postgres::JSONBHash) &&
              klass == Sequel::Postgres::JSONBHash
            end

            def to_array?(klass)
              defined?(Sequel::Postgres::JSONBArray) &&
              klass == Sequel::Postgres::JSONBArray
            end

          end
        end
      end
    end
  end
end