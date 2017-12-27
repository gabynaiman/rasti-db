module Rasti
  module DB
    module Relations
      class OneToOne < OneToMany

        private

        def build_graph_result(rows)
          rows.first
        end

      end
    end
  end
end