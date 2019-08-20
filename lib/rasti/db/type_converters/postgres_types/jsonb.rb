module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class JSONB



          class << self

            def column_type_regex
              /^jsonb$/
            end

            def to_db(value, sub_type)
              Sequel.pg_jsonb value
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
                Sequel::Postgres::JSONBHash => :to_h,
                Sequel::Postgres::JSONBArray => :to_a
              }
            end

          end

        end
      end
    end
  end
end