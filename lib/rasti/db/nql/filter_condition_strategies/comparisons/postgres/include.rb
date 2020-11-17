module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module PostgresComparisons
          class Include < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                Sequel.pg_array(attribute).overlaps Sequel.pg_array(arguments)
              end

              private

              def common_filter_method(attribute, argument)
                Sequel.ilike attribute, "%#{argument}%"
              end

            end
          end
        end
      end
    end
  end
end