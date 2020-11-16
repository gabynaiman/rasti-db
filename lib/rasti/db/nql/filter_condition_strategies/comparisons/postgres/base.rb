module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class Base < Comparisons::Base

            class << self

              private

              def to_pg_array(array)
                Sequel.pg_array(array.map { |element| "\"#{element}\"" })
              end

            end
          end
        end
      end
    end
  end
end