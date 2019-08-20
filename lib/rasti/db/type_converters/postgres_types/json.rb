module Rasti
  module DB
    module TypeConverters
      module PostgresTypes
        class JSON

          class << self

            def column_type_regex
              /^json$/
            end

            def to_db(value:, sub_type:)
              Sequel.pg_json value
            end

            def db_class
              Sequel::Postgres::JSONOp
            end

            def from_db(object:)
              object.value
            end

          end

        end
      end
    end
  end
end