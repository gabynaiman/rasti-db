module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class JSON

          class << self

            def column_type_regex
              /^json$/
            end

            def to_db(value, sub_type)
              Sequel.pg_json value
            end

            def db_classes
              @db_classes ||= from_db_convertions.keys
            end

            def from_db(object)
              object.public_send from_db_convertions[object.class]
            end

            private

            def from_db_convertions
              @from_db_convertions ||= {
                Sequel::Postgres::JSONHash => :to_h,
                Sequel::Postgres::JSONArray => :to_a
              }
            end

          end

        end
      end
    end
  end
end