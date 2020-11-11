module Rasti
  module DB
    module NQL
      module ArrayStrategies
        class SQLiteStrategy < NoneStrategy

          def filter_include(attribute, arguments)
            Sequel.|(*arguments.map { | argument | Sequel.like(attribute, "%\"#{argument}\"%") } )
          end

          def filter_equal(attribute, arguments)
            array = arguments.map { | arg | "\"#{arg}\"" }.join(",")
            { attribute => "[#{array}]" }
          end

          def filter_not_include(attribute, arguments)
            Sequel.&(*arguments.map { | argument | ~Sequel.like(attribute, "%\"#{argument}\"%") } )
          end

          def filter_not_equal(attribute, arguments)
            Sequel.|(*arguments.map { | argument | ~Sequel.like(attribute, "%\"#{argument}\"%") } )
          end

          def filter_like(attribute, arguments)
            Sequel.|(*arguments.map { | argument | Sequel.like(attribute, "%#{argument}%") } )
          end

          def filter_greather_than(attribute, arguments)
            raise MethodNotSupported, 'filter_greather_than'
          end

          def filter_greather_than_or_equal(attribute, arguments)
            raise MethodNotSupported, 'filter_greather_than_or_equal'
          end

          def filter_less_than(attribute, arguments)
            raise MethodNotSupported, 'filter_less_than'
          end

          def filter_less_than_or_equal(attribute, arguments)
            raise MethodNotSupported, 'filter_less_than_or_equal'
          end

        end
      end
    end
  end
end