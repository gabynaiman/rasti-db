require 'minitest_helper'

describe Rasti::DB::TypeConverters::SQLite do

  let(:type_converter) { Rasti::DB::TypeConverters::SQLite }

  let(:sqlite) do
    Object.new.tap do |sqlite|

      def sqlite.opts
        {
          database: 'database'
        }
      end

      def sqlite.schema(table_name, opts={})
        [
          [:text_array, {db_type: 'text[]'}],
        ]
      end

    end
  end

  describe 'Default' do

    it 'must not change value in to_db if column not found in mapping' do
      string = type_converter.to_db sqlite, :table_name, :column, "hola"
      string.class.must_equal String
      string.must_equal "hola"
    end

    it 'must not change value in from_db if class not found in mapping' do
      string = type_converter.from_db "hola"
      string.class.must_equal String
      string.must_equal "hola"
    end

  end

   describe 'Array' do

    describe 'To DB' do

      it 'must transform Array to SQLiteArray' do
        sqlite_array = type_converter.to_db sqlite, :table_name, :text_array, ['a', 'b', 'c']
        sqlite_array.class.must_equal String
        sqlite_array.must_equal '["a","b","c"]'
      end

    end

    describe 'From DB' do

      it 'must transform SQLiteArray to Array' do
        sqlite_array = '["a","b","c"]'
        array = type_converter.from_db sqlite_array
        array.class.must_equal Array
        array.must_equal ['a', 'b', 'c']
      end

    end

  end

end