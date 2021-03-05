module Rasti
  module DB
    class Model < Rasti::Model

      private

      def cast_attribute(type, value)
        super type, Rasti::DB.from_db(value)
      end

    end
  end
end