require 'minitest_helper'

describe 'Type Converter' do

  it 'Apply convertion' do
    type_converter = Rasti::DB::TypeConverter.new db, :users
    type_converter.apply_to(id: '123', name: 'User 1').must_equal id: 123, name: 'User 1'
  end

  describe 'Postgres' do

    let(:pg) do
      Object.new.tap do |pg|
        def pg.database_type
          :postgres
        end

        def pg.schema(table_name, opts={})
          [
            [:hash,          {db_type: 'hstore'}],
            [:text_array,    {db_type: 'text[]'}],
            [:integer_array, {db_type: 'integer[]'}],
            [:hstore_array,  {db_type: 'hstore[]'}]
          ]
        end
      end
    end

    let(:type_converter) { Rasti::DB::TypeConverter.new pg, :table_name }

    it 'HStore' do
      attributes = type_converter.apply_to hash: {key_1: 1, key_2: 2}

      attributes[:hash].class.must_equal Sequel::Postgres::HStore
      attributes[:hash].must_equal 'key_1' => '1', 'key_2' => '2'
    end

    it 'Empty hstore' do
      attributes = type_converter.apply_to hash: {}

      attributes[:hash].class.must_equal Sequel::Postgres::HStore
      attributes[:hash].must_equal Hash.new
    end

    it 'Text array' do
      attributes = type_converter.apply_to text_array: %w(a b c)

      attributes[:text_array].class.must_equal Sequel::Postgres::PGArray
      attributes[:text_array].array_type.must_equal 'text'
      attributes[:text_array].must_equal %w(a b c)
    end
    
    it 'Integer array' do
      attributes = type_converter.apply_to integer_array: [1,2,3]

      attributes[:integer_array].class.must_equal Sequel::Postgres::PGArray
      attributes[:integer_array].array_type.must_equal 'integer'
      attributes[:integer_array].must_equal [1,2,3]
    end

    it 'Hstore array' do
      attributes = type_converter.apply_to hstore_array: [{key: 0}, {key: 1}]

      attributes[:hstore_array].class.must_equal Sequel::Postgres::PGArray
      attributes[:hstore_array].array_type.must_equal 'hstore'
      
      2.times do |i|
        attributes[:hstore_array][i].class.must_equal Sequel::Postgres::HStore
        attributes[:hstore_array][i].must_equal 'key' => i.to_s
      end
    end

    it 'Empty array' do
      attributes = type_converter.apply_to integer_array: []

      attributes[:integer_array].class.must_equal Sequel::Postgres::PGArray
      attributes[:integer_array].array_type.must_equal 'integer'
      attributes[:integer_array].must_equal []
    end

  end

end