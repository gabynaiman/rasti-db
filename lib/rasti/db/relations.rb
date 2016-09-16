module Rasti
  module DB
    module Relations

      class << self

        def graph_to(rows, relations, collection_class, db)
          parse(relations).each do |relation, nested_relations|
            collection_class.relations[relation].graph_to rows, db, nested_relations
          end
        end

        private

        def parse(relations)
          relations.each_with_object({}) do |relation, hash|
            tail = relation.to_s.split '.'
            head = tail.shift.to_sym
            hash[head] ||= []
            hash[head] << tail.join('.') unless tail.empty?
          end
        end

      end


      class Base

        include Sequel::Inflections

        attr_reader :name, :source_collection_class

        def initialize(name, source_collection_class, options={})
          @name = name
          @source_collection_class = source_collection_class
          @options = options
        end

        def target_collection_class
          @target_collection_class ||= @options[:collection].is_a?(Class) ? @options[:collection] : Consty.get(@options[:collection] || camelize(pluralize(name)), self.class)
        end

        private

        attr_reader :options

      end
      

      class OneToMany < Base

        def foreign_key
          @foreign_key ||= @options[:foreign_key] || source_collection_class.implicit_foreign_key_name
        end

        def graph_to(rows, db, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }.uniq

          target_collection = target_collection_class.new db

          relation_rows = target_collection.query do |q|
                            q = q.where foreign_key => pks
                            relations.empty? ? q : q.graph(*relations)
                          end
                          .group_by { |r| r.public_send(foreign_key) }

          rows.each do |row| 
            row[name] = relation_rows.fetch row[source_collection_class.primary_key], []
          end
        end

      end


      class ManyToOne < Base

        def foreign_key
          @foreign_key ||= @options[:foreign_key] || target_collection_class.implicit_foreign_key_name
        end

        def graph_to(rows, db, relations=[])
          fks = rows.map { |row| row[foreign_key] }.uniq

          target_collection = target_collection_class.new db

          relation_rows = target_collection.query do |q|
                            q = q.where source_collection_class.primary_key => fks
                            relations.empty? ? q : q.graph(*relations)
                          end
                          .each_with_object({}) { |r,h| h[r.public_send(source_collection_class.primary_key)] = r }
          
          rows.each do |row| 
            row[name] = relation_rows[row[foreign_key]]
          end
        end

      end


      class ManyToMany < Base

        def source_foreign_key
          @source_foreign_key ||= @options[:source_foreign_key] || source_collection_class.implicit_foreign_key_name
        end

        def target_foreign_key
          @target_foreign_key ||= @options[:target_foreign_key] || target_collection_class.implicit_foreign_key_name
        end

        def relation_collection_name
          @relation_collection_name ||= @options[:relation_collection_name] || [source_collection_class.collection_name, target_collection_class.collection_name].sort.join('_').to_sym
        end

        def graph_to(rows, db, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }

          target_collection = target_collection_class.new db

          join_rows = target_collection.query do |q, ds|
            ds.join(relation_collection_name, target_foreign_key => target_collection_class.primary_key)
              .where("#{relation_collection_name}__#{source_foreign_key}".to_sym => pks)
              .select(Sequel.lit("#{db.quote_identifier(target_collection_class.collection_name)}.*"), source_foreign_key)
          end

          Relations.graph_to join_rows, relations, target_collection_class, db

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash| 
            hash[row[source_foreign_key]] << target_collection_class.model.new(row)
          end

          rows.each do |row| 
            row[name] = relation_rows.fetch row[target_collection_class.primary_key], []
          end
        end

      end

    end
  end
end