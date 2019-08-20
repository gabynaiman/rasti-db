module Rasti
  module DB
    module TypeConverters
      class Postgres

        CONVERTERS = [PostgresTypes::JSON, PostgresTypes::JSONB, PostgresTypes::HStore, PostgresTypes::Array]

        @to_db_mapping = {}
        @from_db_mapping = {}

        class << self

          def to_db(db, collection_name, attribute_name, value)
            to_db_mapping = to_db_mapping_for db, collection_name

            if to_db_mapping.key? attribute_name
              to_db_mapping[attribute_name][:converter].to_db value: value, 
                                                              sub_type: to_db_mapping[attribute_name][:sub_type] 
            else
              value
            end
          end

          def from_db(object)
            if from_db_mapping.key? object.class
              from_db_mapping[object.class].from_db object: object
            else
              object
            end
          end

          private

          def to_db_mapping_for(db, collection_name)
            @to_db_mapping[collection_name] ||= begin
              columns = Hash[db.schema(collection_name)]

              columns.each_with_object({}) do |(name, schema), hash| 
                CONVERTERS.each do |converter|
                  unless hash.key? name
                    match = converter.column_type_regex.match schema[:db_type]

                    hash[name] = {converter: converter, sub_type: match.captures.first} if match
                  end
                end
              end
            end
          end

          def from_db_mapping
            @from_db_mapping ||= begin
              CONVERTERS.each_with_object({}) do |converter, result|
                result[converter.db_class] = converter
              end              
            end
          end

        end

      end
    end
  end
end