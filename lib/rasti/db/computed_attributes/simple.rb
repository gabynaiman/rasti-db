module Rasti
  module DB
    module ComputedAttributes
      class Simple

        def initialize(value:, collection_class:)
          @value = value
          @collection_class = collection_class
        end

        def apply_to(dataset, name)
          dataset.join(query_to(dataset, name), primary_key => primary_key)
        end

        private

        attr_reader :value, :collection_class

        def query_to(dataset, name)
          db_for(dataset).select{|v| [value.as(:value), primary_key] }.as(name)
        end

        def db_for(dataset)
          dataset.db[collection_class.collection_name]
        end

        def primary_key
          collection_class.primary_key
        end

      end
    end
  end
end