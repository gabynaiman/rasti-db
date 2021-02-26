module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class HStore
          class << self

            DB_TYPE_REGEX = /^hstore$/

            def to_db?(type)
              !type.match(DB_TYPE_REGEX).nil?
            end

            def to_db(value, type)
              Sequel.hstore value
            end

            def from_db?(klass)
              defined?(Sequel::Postgres::HStore) &&
              klass == Sequel::Postgres::HStore
            end

            def from_db(value)
              value.to_h
            end

          end
        end
      end
    end
  end
end