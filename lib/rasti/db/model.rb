module Rasti
  module DB
    class Model

      class UninitializedAttributeError < StandardError

        attr_reader :attribute

        def initialize(attribute)
          @attribute = attribute
          super "Uninitialized attribute #{attribute}"
        end

      end


      class << self

        def [](*attribute_names)
          Class.new(self) do
            attribute(*attribute_names)

            def self.inherited(subclass)
              subclass.instance_variable_set :@attributes, attributes.dup
            end
          end
        end

        def attributes
          @attributes ||= []
        end

        def model_name
          name || self.superclass.name
        end

        def to_s
          "#{model_name}[#{attributes.join(', ')}]"
        end
        alias_method :inspect, :to_s

        private

        def attribute(*names)
          names.each do |name|
            raise ArgumentError, "Attribute #{name} already exists" if attributes.include?(name)
            
            attributes << name

            define_method name do
              fetch_attribute name
            end
          end
        end

      end


      def initialize(attributes)
        invalid_attributes = attributes.keys - self.class.attributes
        raise "#{self.class.model_name} invalid attributes: #{invalid_attributes.join(', ')}" unless invalid_attributes.empty?
        @attributes = attributes
      end

      def merge(new_attributes)
        self.class.new attributes.merge(new_attributes)
      end

      def eql?(other)
        instance_of?(other.class) && to_h.eql?(other.to_h)
      end

      def ==(other)
        other.kind_of?(self.class) && to_h == other.to_h
      end

      def hash
        attributes.map(&:hash).hash
      end

      def to_s
        "#<#{self.class.model_name}[#{attributes.map { |n,v| "#{n}: #{v.inspect}" }.join(', ')}]>"
      end
      alias_method :inspect, :to_s

      def to_h
        self.class.attributes.each_with_object({}) do |name, hash|
          if attributes.key? name
            value = fetch_attribute name
            case value
            when Model
              hash[name] = value.to_h
            when Array
              hash[name] = value.map do |e|
                e.is_a?(Model) ? e.to_h : e
              end
            else
              hash[name] = value
            end
          end
        end
      end
      
      private

      attr_reader :attributes

      def fetch_attribute(name)
        attributes.key?(name) ? Rasti::DB.from_db(attributes[name]) : raise(UninitializedAttributeError, name)
      end

    end
  end
end