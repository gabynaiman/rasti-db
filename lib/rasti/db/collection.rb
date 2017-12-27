module Rasti
  module DB
    class Collection

      QUERY_METHODS = (Query::DATASET_CHAINED_METHODS + [:graph, :count, :all, :first, :pluck, :primary_keys, :any?, :empty?, :raw]).freeze

      include Helpers::WithSchema

      class << self

        extend Sequel::Inflections
        include Sequel::Inflections

        def collection_name
          @collection_name ||= underscore(demodulize(name)).to_sym
        end

        def primary_key
          @primary_key ||= :id
        end

        def foreign_key
          @foreign_key ||= "#{singularize(collection_name)}_id".to_sym
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

        private

        def set_collection_name(collection_name)
          @collection_name = collection_name.to_sym
        end

        def set_primary_key(primary_key)
          @primary_key = primary_key
        end

        def set_foreign_key(foreign_key)
          @foreign_key = foreign_key
        end

        def set_model(model)
          @model = model
        end

        [Relations::OneToMany, Relations::ManyToOne, Relations::ManyToMany, Relations::OneToOne].each do |relation_class|
          define_method underscore(demodulize(relation_class.name)) do |name, options={}|
            relations[name] = relation_class.new name, self, options

            query "with_#{pluralize(name)}".to_sym do |primary_keys|
              with_related name, primary_keys
            end
          end
        end

        def query(name, lambda=nil, &block)
          raise "Query #{name} already exists" if queries.key? name

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

      def insert_relations(primary_key, relations)
        relations.each do |relation_name, relation_primary_keys|
          relation = self.class.relations[relation_name]
          insert_relation_table relation, primary_key, relation_primary_keys
        end
        nil
      end

      def update(primary_key, attributes)
        db.transaction do
          db_attributes = type_converter.apply_to attributes
          collection_attributes, relations_primary_keys = split_related_attributes db_attributes
          dataset.where(self.class.primary_key => primary_key).update(collection_attributes) unless collection_attributes.empty?
          save_relations primary_key, relations_primary_keys
        end
        nil
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

      def delete_relations(primary_key, relations)
        db.transaction do
          relations.each do |relation_name, relation_primary_keys|
            relation = self.class.relations[relation_name]
            delete_relation_table relation, primary_key, relation_primary_keys
          end
        end
        nil
      end

      def delete_cascade(*primary_keys)
        db.transaction do
          delete_cascade_relations primary_keys
          bulk_delete { |q| q.where self.class.primary_key => primary_keys }
        end
        nil
      end

      def find(primary_key)
        where(self.class.primary_key => primary_key).first
      end

      def find_graph(primary_key, *relations)
        where(self.class.primary_key => primary_key).graph(*relations).first
      end

      QUERY_METHODS.each do |method|
        define_method method do |*args, &block|
          query.public_send method, *args, &block
        end
      end

      def exists?(filter=nil, &block)
        build_query(filter, &block).any?
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
      
      def query
        Query.new self.class, dataset, [], schema
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
        relations_primary_keys.each do |relation_name, relation_primary_keys|
          relation = self.class.relations[relation_name]
          delete_relation_table relation, [primary_key]
          insert_relation_table relation, primary_key, relation_primary_keys
        end
      end

      def delete_cascade_relations(primary_keys)
        relations = self.class.relations.values

        relations.select(&:many_to_many?).each do |relation|
          delete_relation_table relation, primary_keys
        end

        relations.select { |r| r.one_to_many? || r.one_to_one? }.each do |relation|
          relation_collection_name = with_schema(relation.target_collection_class.collection_name)
          relations_ids = db[relation_collection_name].where(relation.foreign_key => primary_keys)
                                                      .select(relation.target_collection_class.primary_key)
                                                      .map(relation.target_collection_class.primary_key)

          target_collection = relation.target_collection_class.new db, schema
          target_collection.delete_cascade *relations_ids unless relations_ids.empty?
        end
      end

      def insert_relation_table(relation, primary_key, relation_primary_keys)
        relation_collection_name = relation.qualified_relation_collection_name(schema)

        values = relation_primary_keys.map do |relation_pk| 
          {
            relation.source_foreign_key => primary_key, 
            relation.target_foreign_key => relation_pk
          }
        end

        db[relation_collection_name].multi_insert values
      end

      def delete_relation_table(relation, primary_keys, relation_primary_keys=nil)
        relation_collection_name = relation.qualified_relation_collection_name(schema)
        ds = db[relation_collection_name].where(relation.source_foreign_key => primary_keys)
        ds = ds.where(relation.target_foreign_key => relation_primary_keys) if relation_primary_keys
        ds.delete
      end

    end
  end
end