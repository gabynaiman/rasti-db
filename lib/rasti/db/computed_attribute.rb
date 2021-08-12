module Rasti
  module DB
    class ComputedAttribute

      attr_reader :identifier

      def initialize(identifier, &join)
        @identifier = identifier
        @join = join
      end

      def apply_join(dataset, environment = nil)
        join ? join.call(dataset, environment) : dataset
      end

      private

      attr_reader :join

    end
  end
end