module Rasti
  module DB
    module NQL
      module ArrayStrategies

        class ShoudlBeImplemented < StandardError

          attr_reader :method
  
          def initialize(method)
            @method = method
            super "Method #{method} should be implemented in array strategy"
          end
  
        end

        class NoneStrategy

          def filter_include(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_include'
          end

        end

      end
    end
  end
end