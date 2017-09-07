module Rasti
  module DB
    module Helpers
    
      module WithSchema

        private

        def with_schema(table, field=nil)
          qualified_table = schema ? Sequel[schema][table] : table
          field ? Sequel[qualified_table][field] : qualified_table
        end

      end

    end
  end
end