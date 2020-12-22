module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module Types
          class Generic

            def self.equal(identifier, value)
              {identifier => value}
            end

            def self.not_equal(identifier, value)
              Sequel.negate equal(identifier, value)
            end

            def self.greater_than(identifier, value)
              identifier > value
            end

            def self.greater_than_or_equal(identifier, value)
              identifier >= value
            end

            def self.less_than(identifier, value)
              identifier < value
            end

            def self.less_than_or_equal(identifier, value)
              identifier <= value
            end

            def self.like(identifier, value)
              Sequel.ilike identifier, value
            end

            def self.include(identifier, value)
              Sequel.ilike identifier, "%#{value}%"
            end

            def self.not_include(identifier, value)
              ~include(identifier, value)
            end

          end
        end
      end
    end
  end
end