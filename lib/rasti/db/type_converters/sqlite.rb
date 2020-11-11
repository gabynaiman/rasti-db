module Rasti
  module DB
    module TypeConverters
      class SQLite

        CONVERTERS = [SQLiteTypes::Array]

        @to_db_mapping = {}

        class << self

          def to_db(db, collection_name, attribute_name, value)
            to_db_mapping = to_db_mapping_for db, collection_name

            if to_db_mapping.key? attribute_name
              to_db_mapping[attribute_name][:converter].to_db value
            else
              value
            end
          end

          def from_db(object)
            converter = find_converter_from_db object
            if !converter.nil?
              converter.from_db object
            else
              object
            end
          end

          private

          def to_db_mapping_for(db, collection_name)
            key = [db.opts[:database], collection_name]

            @to_db_mapping[key] ||= begin
              columns = Hash[db.schema(collection_name)]

              columns.each_with_object({}) do |(name, schema), hash|
                CONVERTERS.each do |converter|
                  unless hash.key? name
                    match = converter.column_type_regex.match schema[:db_type]

                    hash[name] = { converter: converter } if match
                  end
                end
              end
            end
          end

          def find_converter_from_db(object)
            CONVERTERS.find do |converter|
              converter.respond_for? object
            end
          end

        end

      end
    end
  end
end
