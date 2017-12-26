module Rasti
  module DB
    module Relations

      class << self

        def graph_to(rows, relations, collection_class, db, schema=nil)
          return if rows.empty?

          parse(relations).each do |relation, nested_relations|
            raise "Undefined relation #{relation} for #{collection_class}" unless collection_class.relations.key? relation
            collection_class.relations[relation].graph_to rows, db, schema, nested_relations
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
          @target_collection_class ||= @options[:collection].is_a?(Class) ? @options[:collection] : Consty.get(@options[:collection] || camelize(pluralize(name)), source_collection_class)
        end

        def qualified_source_collection_name(schema=nil)
          schema.nil? ? source_collection_class.collection_name : Sequel.qualify(schema, source_collection_class.collection_name)
        end

        def qualified_target_collection_name(schema=nil)
          schema.nil? ? target_collection_class.collection_name : Sequel.qualify(schema, target_collection_class.collection_name)
        end

        def one_to_many?
          is_a? OneToMany
        end

        def many_to_one?
          is_a? ManyToOne
        end

        def many_to_many?
          is_a? ManyToMany
        end

        private

        attr_reader :options

      end
      

      class OneToMany < Base

        def foreign_key
          @foreign_key ||= @options[:foreign_key] || source_collection_class.foreign_key
        end

        def graph_to(rows, db, schema=nil, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }.uniq

          target_collection = target_collection_class.new db, schema

          relation_rows = target_collection.where(foreign_key => pks)
                                           .graph(*relations)
                                           .group_by { |r| r.public_send(foreign_key) }

          rows.each do |row| 
            row[name] = relation_rows.fetch row[source_collection_class.primary_key], []
          end
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          target_name = qualified_target_collection_name schema

          dataset.join(target_name, foreign_key => source_collection_class.primary_key)
                 .where(Sequel.qualify(target_name, target_collection_class.primary_key) => primary_keys)
                 .select_all(qualified_source_collection_name(schema))
                 .distinct
        end

      end


      class ManyToOne < Base

        def foreign_key
          @foreign_key ||= @options[:foreign_key] || target_collection_class.foreign_key
        end

        def graph_to(rows, db, schema=nil, relations=[])
          fks = rows.map { |row| row[foreign_key] }.uniq

          target_collection = target_collection_class.new db, schema

          relation_rows = target_collection.where(source_collection_class.primary_key => fks)
                                           .graph(*relations)
                                           .each_with_object({}) do |row, hash| 
                                              hash[row.public_send(source_collection_class.primary_key)] = row
                                            end
          
          rows.each do |row| 
            row[name] = relation_rows[row[foreign_key]]
          end
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          dataset.where(foreign_key => primary_keys)
        end

      end


      class ManyToMany < Base

        def source_foreign_key
          @source_foreign_key ||= @options[:source_foreign_key] || source_collection_class.foreign_key
        end

        def target_foreign_key
          @target_foreign_key ||= @options[:target_foreign_key] || target_collection_class.foreign_key
        end

        def relation_collection_name
          @relation_collection_name ||= @options[:relation_collection_name] || [source_collection_class.collection_name, target_collection_class.collection_name].sort.join('_').to_sym
        end

        def qualified_relation_collection_name(schema=nil)
          schema.nil? ? relation_collection_name : Sequel.qualify(schema, relation_collection_name)
        end

        def graph_to(rows, db, schema=nil, relations=[])
          pks = rows.map { |row| row[source_collection_class.primary_key] }

          target_collection = target_collection_class.new db, schema

          relation_name = qualified_relation_collection_name schema

          join_rows = target_collection.dataset
                                       .join(relation_name, target_foreign_key => target_collection_class.primary_key)
                                       .where(Sequel.qualify(relation_name, source_foreign_key) => pks)
                                       .select_all(qualified_target_collection_name(schema))
                                       .select_append(Sequel.qualify(relation_name, source_foreign_key).as(:source_foreign_key))
                                       .all

          Relations.graph_to join_rows, relations, target_collection_class, db, schema

          relation_rows = join_rows.each_with_object(Hash.new { |h,k| h[k] = [] }) do |row, hash| 
            attributes = row.select { |attr,_| target_collection_class.model.attributes.include? attr }
            hash[row[:source_foreign_key]] << target_collection_class.model.new(attributes)
          end

          rows.each do |row| 
            row[name] = relation_rows.fetch row[target_collection_class.primary_key], []
          end
        end

        def apply_filter(dataset, schema=nil, primary_keys=[])
          relation_name = qualified_relation_collection_name schema

          dataset.join(relation_name, source_foreign_key => target_collection_class.primary_key)
                 .where(Sequel.qualify(relation_name, target_foreign_key) => primary_keys)
                 .select_all(qualified_source_collection_name(schema))
                 .distinct
        end

      end

    end
  end
end