module Rasti
  module DB
    module Relations
      class Base
        
        include Sequel::Inflections

        attr_reader :name, :source_collection_class

        def initialize(name, source_collection_class, options={})
          @name = name
          @source_collection_class = source_collection_class
          @options = options
        end

        def target_collection_class
          @target_collection_class ||= options[:collection].is_a?(Class) ? options[:collection] : Consty.get(options[:collection] || camelize(pluralize(name)), source_collection_class)
        end

        def one_to_many?
          self.class == OneToMany
        end

        def many_to_one?
          self.class == ManyToOne
        end

        def many_to_many?
          self.class == ManyToMany
        end

        def one_to_one?
          self.class == OneToOne
        end

        def join_relation_name(prefix)
          with_prefix prefix, name
        end

        private

        attr_reader :options

        def qualified_source_collection_name(schema=nil)
          schema.nil? ? Sequel[source_collection_class.collection_name] : Sequel[schema][source_collection_class.collection_name]
        end

        def qualified_target_collection_name(schema=nil)
          schema.nil? ? Sequel[target_collection_class.collection_name] : Sequel[schema][target_collection_class.collection_name]
        end

        def with_prefix(prefix, name)
          [prefix, name].compact.join('__').to_sym
        end
        
      end
    end
  end
end