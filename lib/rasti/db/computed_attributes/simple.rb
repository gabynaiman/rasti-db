module Rasti
  module DB
    module ComputedAttributes
      class Simple

        def initialize(value:, table:, primary_key:)
          @value = value
          @table = table
          @primary_key = primary_key
        end

        def apply_to(dataset, name)
          dataset.join(query_to(name), primary_key => primary_key)
        end

        private

        attr_reader :value, :table, :primary_key

        def query_to(name)
          table.select{ |v| [value.as(:value), primary_key] }.as(name)
        end

      end
    end
  end
end