require 'sequel'
require 'consty'
require 'time'
require 'timing'
require 'class_config'

require_relative 'db/version'
require_relative 'db/helpers'
require_relative 'db/query'
require_relative 'db/relations/graph_builder'
require_relative 'db/relations/base'
require_relative 'db/relations/one_to_many'
require_relative 'db/relations/one_to_one'
require_relative 'db/relations/many_to_one'
require_relative 'db/relations/many_to_many'
require_relative 'db/collection'
require_relative 'db/model'
require_relative 'db/type_converters/time_in_zone'
require_relative 'db/type_converters/postgres_types/array'
require_relative 'db/type_converters/postgres_types/hstore'
require_relative 'db/type_converters/postgres_types/json'
require_relative 'db/type_converters/postgres_types/jsonb'
require_relative 'db/type_converters/postgres'

module Rasti
  module DB
    
    extend ClassConfig

    attr_config :type_converters, []

    def self.to_db(db, collection_name, attribute_name, value)
      type_converters.inject(value) do |result, type_converter|
        type_converter.to_db db, collection_name, attribute_name, result
      end
    end

    def self.from_db(value)
      type_converters.inject(value) do |result, type_converter|
        type_converter.from_db result
      end
    end

  end
end