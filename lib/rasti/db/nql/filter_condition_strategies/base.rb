module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class Base

          def filter_condition_for(comparison_name, identifier, argument)
            type = type_for argument
            raise UnsupportedTypeComparison.new(type, comparison_name) unless type.respond_to?(comparison_name)
            type.public_send comparison_name, identifier, argument.value
          end

        end
      end
    end
  end
end