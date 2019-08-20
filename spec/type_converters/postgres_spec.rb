require 'minitest_helper'

describe Rasti::DB::TypeConverters::Postgres do

  let(:type_converter) { Rasti::DB::TypeConverters::Postgres }

  let(:pg) do
    Object.new.tap do |pg|

      def pg.schema(table_name, opts={})
        [
          [:hash,          {db_type: 'hstore'}],
          [:text_array,    {db_type: 'text[]'}],
          [:integer_array, {db_type: 'integer[]'}],
          [:hstore_array,  {db_type: 'hstore[]'}],
          [:json,          {db_type: 'json'}],
          [:jsonb,         {db_type: 'jsonb'}]
        ]
      end

    end
  end

  describe 'Default' do

    it 'must not change value in to_db if column not found in mapping' do
      string = type_converter.to_db pg, :table_name, :column, "hola"

      string.class.must_equal String
      string.must_equal "hola"
    end

    it 'must not change value in from_db if class not found in mapping' do
      string = type_converter.from_db "hola"

      string.class.must_equal String
      string.must_equal "hola"
    end

  end


  describe 'HStore' do

    describe 'To DB' do
      
      it 'must transform Hash to HStore' do
        hstore = type_converter.to_db pg, :table_name, :hash, {key_1: 1, key_2: 2}

        hstore.class.must_equal Sequel::Postgres::HStore
        hstore.must_equal 'key_1' => '1', 'key_2' => '2'
      end

      it 'must transform empty hash to HStore' do
        hstore = type_converter.to_db pg, :table_name, :hash, {}

        hstore.class.must_equal Sequel::Postgres::HStore
        hstore.must_be_empty
      end

    end

    describe 'From DB' do

      it 'must transform HStore to Hash' do
        hstore = Sequel::Postgres::HStore.new 'key_1' => '1', 'key_2' => '2'
        hash = type_converter.from_db hstore
        
        hash.class.must_equal Hash
        hash.must_equal hstore
      end

    end

  end

  describe 'Array' do

    describe 'To DB' do

      it 'must transform String[] to PGArray' do
        pg_array = type_converter.to_db pg, :table_name, :text_array, %w(a b c)

        pg_array.class.must_equal Sequel::Postgres::PGArray
        pg_array.array_type.must_equal 'text'
        pg_array.must_equal %w(a b c)
      end

      it 'must transform Integer[] to PGArray' do
        pg_array = type_converter.to_db pg, :table_name, :integer_array, [1,2,3]

        pg_array.class.must_equal Sequel::Postgres::PGArray
        pg_array.array_type.must_equal 'integer'
        pg_array.must_equal [1,2,3]
      end

      it 'must transform Hstore[] to PGArray' do
        pg_array = type_converter.to_db pg, :table_name, :hstore_array, [{key: 0}, {key: 1}]

        pg_array.class.must_equal Sequel::Postgres::PGArray
        pg_array.array_type.must_equal 'hstore'
        
        pg_array.each_with_index do |element, index|
          element.class.must_equal Sequel::Postgres::HStore
          element.must_equal 'key' => index.to_s
        end
      end

      it 'Must transform empty array to PGArray' do
        pg_array = type_converter.to_db pg, :table_name, :integer_array, []

        pg_array.class.must_equal Sequel::Postgres::PGArray
        pg_array.array_type.must_equal 'integer'
        pg_array.must_be_empty
      end
    
    end

    describe 'From DB' do

      it 'must transform PGArray to Array' do
        pg_array = Sequel::Postgres::PGArray.new [1,2,3]
        array = type_converter.from_db pg_array

        array.class.must_equal Array
        array.must_equal pg_array
      end

    end

  end
  
  describe 'JSON' do

    let(:json_hash) { {key_1: {key_2: [3]}} }
    let(:json_array) { [{key_1: {key_2: [3]}}] }

    describe 'To DB' do

      it 'must transform Hash to JSONHash' do
        pg_json_hash = type_converter.to_db pg, :table_name, :json, json_hash

        pg_json_hash.class.must_equal Sequel::Postgres::JSONHash
        pg_json_hash.must_equal json_hash
      end

      it 'must transform Array to JSONArray' do
        pg_json_array = type_converter.to_db pg, :table_name, :json, json_array

        pg_json_array.class.must_equal Sequel::Postgres::JSONArray
        pg_json_array.must_equal json_array
      end

    end

    describe 'From DB' do

      it 'must transform JSONHash to Hash' do
        pg_json_hash = Sequel::Postgres::JSONHash.new json_hash
        hash = type_converter.from_db pg_json_hash

        hash.class.must_equal Hash
        hash.must_equal pg_json_hash
      end

      it 'must transform JSONArray to Array' do
        pg_json_array = Sequel::Postgres::JSONArray.new json_array
        array = type_converter.from_db pg_json_array

        array.class.must_equal Array
        array.must_equal pg_json_array
      end

    end

  end

  describe 'JSONB' do

    let(:json_hash) { {key_1: {key_2: [3]}} }
    let(:json_array) { [{key_1: {key_2: [3]}}] }

    describe 'To DB' do

      it 'must transform Hash to JSONBHash' do
        pg_jsonb_hash = type_converter.to_db pg, :table_name, :jsonb, json_hash

        pg_jsonb_hash.class.must_equal Sequel::Postgres::JSONBHash
        pg_jsonb_hash.must_equal json_hash
      end

      it 'must transform Array to JSONBArray' do
        pg_jsonb_array = type_converter.to_db pg, :table_name, :jsonb, json_array

        pg_jsonb_array.class.must_equal Sequel::Postgres::JSONBArray
        pg_jsonb_array.must_equal json_array
      end

    end

    describe 'From DB' do

      it 'must transform JSONBHash to Hash' do
        pg_jsonb_hash = Sequel::Postgres::JSONBHash.new json_hash
        hash = type_converter.from_db pg_jsonb_hash

        hash.class.must_equal Hash
        hash.must_equal pg_jsonb_hash
      end

      it 'must transform JSONBArray to Array' do
        pg_jsonb_array = Sequel::Postgres::JSONBArray.new json_array
        array = type_converter.from_db pg_jsonb_array

        array.class.must_equal Array
        array.must_equal pg_jsonb_array
      end

    end

  end

end