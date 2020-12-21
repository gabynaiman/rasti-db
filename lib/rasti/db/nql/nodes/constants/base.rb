module Rasti
  module DB
    module NQL
      module Nodes
        module Constants
          class Base < Treetop::Runtime::SyntaxNode

            def type
              Inflecto.underscore(Inflecto.demodulize(self.class)).to_sym
            end

            def add_values(value_array)
              value_array.push(value)
            end

          end
        end
      end
    end
  end
end