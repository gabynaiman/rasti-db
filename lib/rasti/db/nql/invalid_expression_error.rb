module Rasti
  module DB
    module NQL
      class InvalidExpressionError < StandardError

        attr_reader :expression

        def initialize(expression)
          @expression = expression
        end

        def message
          "Invalid filter expression: #{expression}"
        end

      end
    end
  end
end