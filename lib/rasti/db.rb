require 'sequel'
require 'rasti-model'
require 'consty'
require 'time'
require 'timing'
require 'treetop'
require 'hierarchical_graph'
require 'class_config'
require 'hash_ext'
require 'inflecto'
require 'multi_require'

module Rasti
  module DB

    extend MultiRequire
    extend ClassConfig

    require_relative         'db/query'
    require_relative_pattern 'db/relations/*'
    require_relative_pattern 'db/type_converters/postgres_types/*'
    require_relative_pattern 'db/type_converters/sqlite_types/*'
    require_relative         'db/nql/nodes/constants/base'
    require_relative_pattern 'db/nql/filter_condition_strategies/types/*'
    require_relative_pattern 'db/**/*'

    attr_config :type_converters, []
    attr_config :nql_filter_condition_strategy, nil

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

    def self.nql_filter_condition_for(comparison_name, identifier, argument)
      raise 'Undefined Rasti::DB.nql_filter_condition_strategy' unless nql_filter_condition_strategy
      nql_filter_condition_strategy.filter_condition_for comparison_name, identifier, argument
    end

  end
end