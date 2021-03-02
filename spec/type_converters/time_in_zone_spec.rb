require 'minitest_helper'

describe Rasti::DB::TypeConverters::TimeInZone do

  let(:type_converter) { Rasti::DB::TypeConverters::TimeInZone }

  describe 'To DB' do

    it 'must not transform Time to TimeInZone' do
      time = Timing::TimeInZone.now

      converted_time = type_converter.to_db db, 'table', :time, time

      converted_time.class.must_equal Time
      converted_time.must_equal time
    end

  end

  describe 'From DB' do

    it 'must transform Time to TimeInZone' do
      time = Time.now

      converted_time = type_converter.from_db time

      converted_time.class.must_equal Timing::TimeInZone
      converted_time.must_equal time
    end

  end

end