module Rasti
  module DB
    module TypeConverters
      module SQLiteTypes
        class Array

          class << self

            def column_type_regex
              /^([a-z]+)\[\]$/
            end

            def to_db(values)
              JSON.dump(values)
            end

            def respond_for?(object)
              parsed = JSON.parse object
              object == to_db(parsed)
            rescue
              false
            end

            def from_db(object)
              JSON.parse object
            end

          end

        end
      end
    end
  end
end