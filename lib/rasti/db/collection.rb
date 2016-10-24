module Rasti
  module DB
    class Collection

      QUERY_METHODS = (Query::DATASET_CHAINED_METHODS + [:graph, :count, :all, :first]).freeze

      class << self

        include Sequel::Inflections

        def collection_name
          @collection_name ||= implicit_collection_name
        end

        def primary_key
          @primary_key ||= :id
        end

        def model
          if @model.is_a? Class
            @model
          elsif @model
            @model = Consty.get @model, self
          else
            @model = Consty.get demodulize(singularize(name)), self
          end
        end

        def relations
          @relations ||= {}
        end

        def queries
          @queries ||= {}
        end

        def implicit_collection_name
          underscore(demodulize(name)).to_sym
        end

        def implicit_foreign_key_name
          "#{singularize(collection_name)}_id".to_sym
        end

        private

        def set_collection_name(collection_name)
          @collection_name = collection_name.to_sym
        end

        def set_primary_key(primary_key)
          @primary_key = primary_key
        end

        def set_model(model)
          @model = model
        end

        def one_to_many(name, options={})
          relations[name] = Relations::OneToMany.new name, self, options
        end

        def many_to_one(name, options={})
          relations[name] = Relations::ManyToOne.new name, self, options
        end

        def many_to_many(name, options={})
          relations[name] = Relations::ManyToMany.new name, self, options
        end

        def query(name, lambda=nil, &block)
          queries[name] = lambda || block
          
          define_method name do |*args|
            query.instance_exec *args, &self.class.queries[name]
          end
        end

      end

      attr_reader :db, :schema

      def initialize(db, schema=nil)
        @db = db
        @schema = schema
      end

      def dataset
        db[qualified_collection_name]
      end

      def insert(attributes)
        db.transaction do
          db_attributes = type_converter.apply_to attributes
          collection_attributes, relations_primary_keys = split_related_attributes db_attributes
          primary_key = dataset.insert collection_attributes
          save_relations primary_key, relations_primary_keys
          primary_key
        end
      end

      def bulk_insert(attributes, options={})
        db_attributes = type_converter.apply_to attributes
        dataset.multi_insert db_attributes, options
      end

      def update(primary_key, attributes)
        db.transaction do
          db_attributes = type_converter.apply_to attributes
          collection_attributes, relations_primary_keys = split_related_attributes db_attributes
          dataset.where(self.class.primary_key => primary_key).update(collection_attributes) unless collection_attributes.empty?
          save_relations primary_key, relations_primary_keys
          nil
        end
      end

      def bulk_update(attributes, &block)
        db_attributes = type_converter.apply_to attributes
        build_query(&block).instance_eval { dataset.update db_attributes }
        nil
      end

      def delete(primary_key)
        dataset.where(self.class.primary_key => primary_key).delete
        nil
      end

      def bulk_delete(&block)
        build_query(&block).instance_eval { dataset.delete }
        nil
      end

      def find(primary_key)
        where(self.class.primary_key => primary_key).first
      end

      def find_graph(primary_key, *relations)
        raise ArgumentError, 'must specify relations for graph' if relations.empty?
        where(self.class.primary_key => primary_key).graph(*relations).first
      end

      def query
        Query.new self.class, dataset, [], schema
      end

      QUERY_METHODS.each do |method|
        define_method method do |*args, &block|
          query.public_send method, *args, &block
        end
      end

      def exists?(filter=nil, &block)
        build_query(filter, &block).count > 0
      end

      def detect(filter=nil, &block)
        build_query(filter, &block).first
      end

      private

      def type_converter
        @type_converter ||= TypeConverter.new db, qualified_collection_name
      end

      def qualified_collection_name
        schema.nil? ? self.class.collection_name : Sequel.qualify(schema, self.class.collection_name)
      end
      
      def build_query(filter=nil, &block)
        raise ArgumentError, 'must specify filter hash or block' if filter.nil? && block.nil?
        if filter
          query.where filter
        else
          block.arity == 0 ? query.instance_eval(&block) : block.call(query)
        end
      end

      def split_related_attributes(attributes)
        relation_names = self.class.relations.values.select(&:many_to_many?).map(&:name)

        collection_attributes = attributes.reject { |n,v| relation_names.include? n }
        relations_ids = attributes.select { |n,v| relation_names.include? n }

        [collection_attributes, relations_ids]
      end
      
      def save_relations(primary_key, relations_primary_keys)
        relations_primary_keys.each do |relation_name, primary_keys|
          relation = self.class.relations[relation_name]
          relation_collection_name = relation.qualified_relation_collection_name(schema)
          
          values = primary_keys.map do |rel_primary_key| 
            {
              relation.source_foreign_key => primary_key, 
              relation.target_foreign_key => rel_primary_key
            }
          end
          
          db[relation_collection_name].where(relation.source_foreign_key => primary_key).delete
          db[relation_collection_name].multi_insert values
        end
      end

    end
  end
end