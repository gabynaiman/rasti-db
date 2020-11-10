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

        end
      end
    end
  end
end