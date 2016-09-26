module Rasti
  module DB
    class Collection

      class << self

        include Sequel::Inflections

        def collection_name
          @collection_name ||= implicit_collection_name
        end

        def primary_key
          @primary_key ||= :id
        end

        def model
          @model ||= Consty.get(demodulize(singularize(name)), self)
        end

        def relations
          @relations ||= {}
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

      end

      def initialize(db, schema=nil)
        @db = db
        @schema = schema
      end

      def insert(attributes)
        db.transaction do
          collection_attributes, relations_primary_keys = split_related_attributes attributes
          primary_key = dataset.insert collection_attributes
          save_relations primary_key, relations_primary_keys
          primary_key
        end
      end

      def update(primary_key, attributes)
        db.transaction do
          collection_attributes, relations_primary_keys = split_related_attributes attributes
          updated_count = dataset.where(self.class.primary_key => primary_key).update(collection_attributes) unless collection_attributes.empty?
          save_relations primary_key, relations_primary_keys
          updated_count
        end
      end

      def delete(primary_key)
        dataset.where(self.class.primary_key => primary_key).delete
      end

      def find(primary_key)
        query { |q| q.where(self.class.primary_key => primary_key).first }
      end

      def count
        dataset.count
      end

      def all
        query { all }
      end

      def first
        query { first }
      end

      def query(&block)
        query = Query.new self.class, dataset, schema
        result = block.arity == 0 ? query.instance_eval(&block) : block.call(query, dataset)
        result.respond_to?(:all) ? result.all : result
      end

      private

      attr_reader :db, :schema
      
      def dataset
        db[schema.nil? ? self.class.collection_name : "#{schema}__#{self.class.collection_name}".to_sym]
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