module Rasti
  module DB
    module TypeConverters
      module Postgres
        class JSONB

          class << self

            def column_type_regex
              /^jsonb$/
            end

            def to_db(value:, sub_type:)
              Sequel.pg_jsonb value
            end

            def db_class
              Sequel::Postgres::JSONBHash
            end

            def from_db(object:)
              object.to_h
            end

          end

        end
      end
    end
  end
end