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

          def filter_equal(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_equal'
          end

          def filter_greather_than(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_greather_than'
          end

          def filter_greather_than_or_equal(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_greather_than_or_equal'
          end

          def filter_less_than(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_less_than'
          end

          def filter_less_than_or_equal(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_less_than_or_equal'
          end

          def filter_like(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_like'
          end

          def filter_not_equal(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_not_equal'
          end

          def filter_not_include(attribute, arguments)
            raise ShoudlBeImplemented, 'filter_not_include'
          end

        end

      end
    end
  end
end