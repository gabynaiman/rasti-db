module Rasti
  module DB
    module NQL

      class Sentence < Treetop::Runtime::SyntaxNode
      end

      class Disjunction < Treetop::Runtime::SyntaxNode
      end

      class Conjunction < Treetop::Runtime::SyntaxNode
      end

      class ParenthesisSentence < Treetop::Runtime::SyntaxNode
      end

      class StringComparison < Treetop::Runtime::SyntaxNode
      end

      class QuantityComparison < Treetop::Runtime::SyntaxNode
      end
      
      class BooleanComparison < Treetop::Runtime::SyntaxNode
      end

      class Field < Treetop::Runtime::SyntaxNode
      end

      class TimeConstant < Treetop::Runtime::SyntaxNode
      end

      class Date < Treetop::Runtime::SyntaxNode
      end

      class TimeZone < Treetop::Runtime::SyntaxNode
      end

      class LiteralStringConstant < Treetop::Runtime::SyntaxNode
      end

      class StringConstant < Treetop::Runtime::SyntaxNode
      end

      class TrueConstant < Treetop::Runtime::SyntaxNode
      end

      class FalseConstant < Treetop::Runtime::SyntaxNode
      end

      class FloatConstant < Treetop::Runtime::SyntaxNode
      end

      class IntegerConstant < Treetop::Runtime::SyntaxNode

        def value
          text_value.to_i  
        end

      end

    end
  end
end