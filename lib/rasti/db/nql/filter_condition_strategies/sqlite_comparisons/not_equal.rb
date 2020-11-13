module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module SQLiteComparisons
          class NotEqual < Base
            class << self

              def for_array(attribute, arguments)
                Sequel.|(*arguments.map { | argument | ~Sequel.like(attribute, "%\"#{argument}\"%") } )
              end

              private

              def common_filter_method(attribute, argument)
                Sequel.negate attribute => argument
              end

            end
          end
        end
      end
    end
  end
end