module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        module SQLiteComparisons
          class NotInclude < Comparisons::Base
            class << self

              def for_array(attribute, arguments)
                Sequel.&(*arguments.map { | argument | ~Sequel.like(attribute, "%\"#{argument}\"%") } )
              end

              private

              def common_filter_method(attribute, argument)
                ~ Sequel.ilike(attribute, "%#{argument}%")
              end

            end
          end
        end
      end
    end
  end
end