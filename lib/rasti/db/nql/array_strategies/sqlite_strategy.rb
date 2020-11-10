module Rasti
  module DB
    module NQL
      module ArrayStrategies
        class SQLiteStrategy

          def filter_include(attribute, arguments)
            Sequel.|(*arguments.map { |argument| Sequel.like(attribute, "%\"#{argument}\"%") } )
          end

        end
      end
    end
  end
end