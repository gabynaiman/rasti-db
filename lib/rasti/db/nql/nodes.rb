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

      class Comparison < Treetop::Runtime::SyntaxNode
      end

      class Field < Treetop::Runtime::SyntaxNode

        def tables
          _tables.elements.map{ |e| e.table.text_value }
        end

        def column
          _column.text_value
        end

      end

      class TimeConstant < Treetop::Runtime::SyntaxNode

        def value
          Timing::TimeInZone.parse text_value
        end

      end

      class Date < Treetop::Runtime::SyntaxNode
      end

      class TimeZone < Treetop::Runtime::SyntaxNode
      end

      class LiteralStringConstant < Treetop::Runtime::SyntaxNode
      
        def value
          string.text_value
        end

      end

      class StringConstant < Treetop::Runtime::SyntaxNode

        def value
          text_value
        end

      end

      class TrueConstant < Treetop::Runtime::SyntaxNode

        def value
          true
        end

      end

      class FalseConstant < Treetop::Runtime::SyntaxNode

        def value
          false
        end

      end

      class FloatConstant < Treetop::Runtime::SyntaxNode

        def value
          text_value.to_f
        end

      end

      class IntegerConstant < Treetop::Runtime::SyntaxNode

        def value
          text_value.to_i  
        end

      end

    end
  end
end