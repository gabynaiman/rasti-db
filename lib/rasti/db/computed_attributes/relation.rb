module Rasti
  module DB
    module ComputedAttributes
      class Relation

        def initialize(value:, table:, type:, attributes:, foreign_key:)
          @value = value
          @table = table
          @type = type
          @attributes = attributes
          @foreign_key = foreign_key
        end

        def apply_to(dataset, name)
          dataset.join_table(type, query_to(name), foreign_key => :id)
        end

        private

        attr_reader :value, :table, :type, :attributes, :foreign_key

        def query_to(name)
          table.select{ |v| [value.as(:value), *attributes] }.group(foreign_key).as(name)
        end

      end
    end
  end
end