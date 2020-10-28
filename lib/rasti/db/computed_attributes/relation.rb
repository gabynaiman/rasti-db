module Rasti
  module DB
    module ComputedAttributes
      class Relation

        def initialize(value:, table:, type:, foreign_key:, primary_key: :id, attributes: [])
          @value = value
          @table = table
          @type = type
          @foreign_key = foreign_key
          @primary_key = primary_key
          @attributes = attributes.push foreign_key
        end

        def apply_to(dataset, name)
          dataset.join_table(type, query_to(name), foreign_key => primary_key)
        end

        private

        attr_reader :value, :table, :type, :foreign_key, :primary_key, :attributes

        def query_to(name)
          table.select{ |v| [value.as(:value), *attributes] }.group(foreign_key).as(name)
        end

      end
    end
  end
end