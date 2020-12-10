module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module Types
          class SQLiteArray

            def self.equal(identifier, values)
              array = values.map { |value| "\"#{value}\"" }.join(',')
              {identifier => "[#{array}]"}
            end

            def self.not_equal(identifier, values)
              Sequel.|(*values.map { |value| ~Sequel.like(identifier, "%\"#{value}\"%") })
            end

            def self.like(identifier, values)
              Sequel.|(*values.map { |value| Sequel.like(identifier, "%#{value}%") })
            end

            def self.include(identifier, values)
              Sequel.|(*values.map { |value| Sequel.like(identifier, "%\"#{value}\"%") })
            end

            def self.not_include(identifier, values)
              Sequel.&(*values.map { |value| ~Sequel.like(identifier, "%\"#{value}\"%") })
            end

          end
        end
      end
    end
  end
end