require 'minitest_helper'

describe Rasti::DB::TypeConverters::SQLite do

  let(:type_converter) { Rasti::DB::TypeConverters::SQLite }

  describe 'To DB' do

    it 'must transform value in integer column' do
      id = type_converter.to_db db, :users, :id, '123'

      id.must_equal 123
    end

  end
  
end