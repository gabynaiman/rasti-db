module Rasti
  module DB
    class Collection

      QUERY_METHODS = Query.public_instance_methods - Object.public_instance_methods

      class << self

        extend Sequel::Inflections
        include Sequel::Inflections

        def collection_name
          @collection_name ||= underscore(demodulize(name)).to_sym
        end

        def collection_attributes
          @collection_attributes ||= model.attributes - relations.keys
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

        def data_source_name
          @data_source_name ||= :default
        end

        def relations
          @relations ||= Hash::Indifferent.new
        end

        def queries
          @queries ||= Hash::Indifferent.new
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

        def data_source(name)
          @data_source_name = name.to_sym
        end

        [Relations::OneToMany, Relations::ManyToOne, Relations::ManyToMany, Relations::OneToOne].each do |relation_class|
          define_method underscore(demodulize(relation_class.name)) do |name, options={}|
            relations[name] = relation_class.new name, self, options

            query "with_#{pluralize(singularize(name))}" do |primary_keys|
              with_related name, primary_keys
            end
          end
        end

        def query(name, lambda=nil, &block)
          raise "Query #{name} already exists" if queries.key? name

          queries[name] = lambda || block
          
          define_method name do |*args|
            default_query.instance_exec(*args, &self.class.queries.fetch(name))
          end
        end

      end

      def initialize(environment)
        @environment = environment
      end

      QUERY_METHODS.each do |method|
        define_method method do |*args, &block|
          default_query.public_send method, *args, &block
        end
      end

      def insert(attributes)
        data_source.db.transaction do
          db_attributes = transform_attributes_to_db attributes
          collection_attributes, relations_primary_keys = split_related_attributes db_attributes
          primary_key = dataset.insert collection_attributes
          save_relations primary_key, relations_primary_keys
          primary_key
        end
      end

      def bulk_insert(attributes, options={})
        db_attributes = attributes.map { |attrs| transform_attributes_to_db attrs }
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
        data_source.db.transaction do
          db_attributes = transform_attributes_to_db attributes
          collection_attributes, relations_primary_keys = split_related_attributes db_attributes
          dataset.where(self.class.primary_key => primary_key).update(collection_attributes) unless collection_attributes.empty?
          save_relations primary_key, relations_primary_keys
        end
        nil
      end

      def bulk_update(attributes, &block)
        db_attributes = transform_attributes_to_db attributes
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
        data_source.db.transaction do
          relations.each do |relation_name, relation_primary_keys|
            relation = self.class.relations[relation_name]
            delete_relation_table relation, primary_key, relation_primary_keys
          end
        end
        nil
      end

      def delete_cascade(*primary_keys)
        data_source.db.transaction do
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

      def exists?(filter=nil, &block)
        build_query(filter, &block).any?
      end

      def detect(filter=nil, &block)
        build_query(filter, &block).first
      end

      private

      attr_reader :environment

      def data_source
        @data_source ||= environment.data_source_of self.class
      end

      def dataset
        data_source.db[qualified_collection_name]
      end

      def qualified_collection_name
        data_source.qualify self.class.collection_name
      end
      
      def qualify(collection_name, data_source_name: nil)
        data_source_name ||= self.class.data_source_name
        environment.qualify data_source_name, collection_name
      end

      def default_query
        Query.new collection_class: self.class, 
                  dataset: dataset.select_all(self.class.collection_name), 
                  environment: environment
      end

      def build_query(filter=nil, &block)
        raise ArgumentError, 'must specify filter hash or block' if filter.nil? && block.nil?
        
        if filter
          default_query.where(filter)
        else
          block.arity == 0 ? default_query.instance_eval(&block) : block.call(default_query)
        end
      end

      def transform_attributes_to_db(attributes)
        attributes.each_with_object({}) do |(attribute_name, value), result| 
          transformed_value = Rasti::DB.to_db data_source.db, qualified_collection_name, attribute_name, value
          result[attribute_name] = transformed_value
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
          relation_data_source = environment.data_source_of relation.target_collection_class
          relation_collection_name = relation_data_source.qualify relation.target_collection_class.collection_name

          relations_ids = relation_data_source.db[relation_collection_name]
                                              .where(relation.foreign_key => primary_keys)
                                              .select(relation.target_collection_class.primary_key)
                                              .map(relation.target_collection_class.primary_key)

          target_collection = relation.target_collection_class.new environment
          target_collection.delete_cascade(*relations_ids) unless relations_ids.empty?
        end
      end

      def insert_relation_table(relation, primary_key, relation_primary_keys)
        relation_data_source = environment.data_source relation.relation_data_source_name
        relation_collection_name = relation_data_source.qualify relation.relation_collection_name

        values = relation_primary_keys.map do |relation_pk| 
          {
            relation.source_foreign_key => primary_key, 
            relation.target_foreign_key => relation_pk
          }
        end

        relation_data_source.db[relation_collection_name].multi_insert values
      end

      def delete_relation_table(relation, primary_keys, relation_primary_keys=nil)
        relation_data_source = environment.data_source relation.relation_data_source_name
        relation_collection_name = relation_data_source.qualify relation.relation_collection_name

        ds = relation_data_source.db[relation_collection_name].where(relation.source_foreign_key => primary_keys)
        ds = ds.where(relation.target_foreign_key => relation_primary_keys) if relation_primary_keys
        ds.delete
      end

    end
  end
end