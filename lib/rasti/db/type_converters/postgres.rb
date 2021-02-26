module Rasti
  module DB
    module TypeConverters
      class Postgres

        CONVERTERS = [
          PostgresTypes::JSON,
          PostgresTypes::JSONB,
          PostgresTypes::HStore,
          PostgresTypes::Array
        ]

        class << self

          def to_db(db, collection_name, attribute_name, value)
            converter, type = find_to_db_converter_and_type db, collection_name, attribute_name
            converter ? converter.to_db(value, type) : value
          end

          def from_db(value)
            converter = find_from_db_converter value.class
            converter ? converter.from_db(value) : value
          end

          private

          def from_db_converters
            @from_db_converters ||= {}
          end

          def to_db_converters
            @to_db_converters ||= {}
          end

          def find_to_db_converter_and_type(db, collection_name, attribute_name)
            key = [db.opts[:database], collection_name].join('.')

            to_db_converters[key] ||= begin
              columns = Hash[db.schema(collection_name)]
              to_db_converters[key] = columns.each_with_object({}) do |(name, schema), hash|
                converter = CONVERTERS.detect { |c| c.to_db? schema[:db_type] }
                hash[name] = [converter, schema[:db_type]] if converter
              end
            end

            to_db_converters[key].fetch(attribute_name, [])
          end

          def find_from_db_converter(klass)
            if !from_db_converters.key?(klass)
              from_db_converters[klass] = CONVERTERS.detect { |c| c.from_db? klass }
            end

            from_db_converters[klass]
          end

        end
      end
    end
  end
end