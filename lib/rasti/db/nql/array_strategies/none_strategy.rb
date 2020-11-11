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

        class MethodNotSupported < StandardError

          attr_reader :method

          def initialize(method)
            @method = method
            super "Method #{method} have not support for this array strategy"
          end

        end

        class NoneStrategy

          FILTER_METHODS = [
            :filter_include,
            :filter_equal,
            :filter_greather_than,
            :filter_greather_than_or_equal,
            :filter_less_than,
            :filter_less_than_or_equal,
            :filter_like,
            :filter_not_equal,
            :filter_not_include
          ]

          FILTER_METHODS.each do |method|
            define_method method do |*args, &block|
              raise ShoudlBeImplemented, method
            end
          end

        end

      end
    end
  end
end