module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module Types
          class PGArray

            def self.equal(identifier, values)
              Sequel.&(
                Sequel.pg_array(identifier).contains(Sequel.pg_array(values)),
                Sequel.pg_array(identifier).contained_by(Sequel.pg_array(values))
              )
            end

            def self.not_equal(identifier, values)
              ~equal(identifier, values)
            end

            def self.include(identifier, values)
              Sequel.pg_array(identifier).overlaps Sequel.pg_array(values)
            end

            def self.not_include(identifier, values)
              ~include(identifier, values)
            end

          end
        end
      end
    end
  end
end