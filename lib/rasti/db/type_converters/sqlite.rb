module Rasti
  module DB
    module TypeConverters
      class SQLite

        @to_db_mapping = {}

        class << self

          def to_db(db, collection_name, attribute_name, value)
            db_mapping = to_db_mapping_for db, collection_name 

            if db_mapping.key?(attribute_name) && /integer/.match(db_mapping[attribute_name])
              value.to_i
            else
              value
            end
          end

          def from_db(object)
            object
          end

          private

          def to_db_mapping_for(db, collection_name)
            @to_db_mapping[collection_name] ||= begin
              columns = Hash[db.schema(collection_name)]

              columns.each_with_object({}) do |(name, schema), hash|
                hash[name] = schema[:db_type]
              end
            end
          end

        end

      end
    end
  end
end
