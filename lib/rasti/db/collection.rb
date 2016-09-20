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
        dataset.insert attributes
      end

      def update(primary_key, attributes)
        dataset.where(self.class.primary_key => primary_key).update(attributes)
      end

      def delete(primary_key)
        dataset.where(self.class.primary_key => primary_key).delete
      end

      def fetch(primary_key)
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
        query = Query.new self.class, dataset
        result = block.arity == 0 ? query.instance_eval(&block) : block.call(query, dataset)
        result.respond_to?(:all) ? result.all : result
      end

      private

      attr_reader :db, :schema
      
      def dataset
        db[schema.nil? ? self.class.collection_name : "#{schema}__#{self.class.collection_name}".to_sym]
      end

    end
  end
end