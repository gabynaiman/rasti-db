module Rasti
  module DB
    module TypeConverters
      class Postgres

        POSTGRES_CONVERTERS = [Postgres::JSON, Postgres::JSONB, Postgres::HStore, Postgres::Array]

        @to_db_mapping = {}
        @from_db_mapping = {}

        class << self

          def to_db(db, collection_name, attribute_name, value)
            convertions = convertions_for(db, collection_name)

            if convertions.key? attribute_name
              convertions[attribute_name][:block].call value, convertions[attribute_name][:match] 
            else
              value
            end
          end

          def from_db(object)

          end

          private

          def to_db_mapping_for(db, collection_name)
            @to_db_mapping[collection_name] ||= begin
              columns = Hash[db.schema(collection_name)]

              columns.each_with_object({}) do |(name, schema), hash| 
                TO_DB_MAPPING.each do |type, convertion|
                  match = type.match schema[:db_type]

                  hash[name] ||= {match: match, block: convertion} if match
                end
              end
            end
          end 

        end

      end
    end
  end
end