module Rasti
  module DB
    module NQL
      module FilterConditionStrategies
        class UnsupportedTypeComparison < StandardError

          attr_reader :argument_type, :comparison_name

          def initialize(argument_type, comparison_name)
            @argument_type = argument_type
            @comparison_name = comparison_name
          end

          def message
            "Unsupported comparison #{comparison_name} for #{argument_type}"
          end

        end
      end
    end
  end
end