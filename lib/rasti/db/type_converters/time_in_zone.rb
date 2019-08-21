module Rasti
  module DB
    module TypeConverters
      class TimeInZone

        class << self

          def to_db(db, collection_name, attribute_name, value)
            value
          end

          def from_db(value)
            value.is_a?(Time) ? Timing::TimeInZone.new(value) : value
          end

        end

      end
    end
  end
end