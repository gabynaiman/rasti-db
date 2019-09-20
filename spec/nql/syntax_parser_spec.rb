require 'minitest_helper'

describe 'SyntaxParser' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  describe 'Comparison' do

    describe 'Comparators' do
      
      ['=', '!=', '>', '>=', '<', '<=', '~', ':', '!:'].each do |comparator|
        it "must parse expression with '#{comparator}'" do
          tree = parser.parse "column #{comparator} value"
          tree.wont_be_nil

          proposition = tree.proposition
          proposition.comparator.text_value.must_equal comparator
          proposition.left.text_value.must_equal 'column'
          proposition.right.text_value.must_equal 'value'
        end
      end

    end

    it "must parse expression without spaces between elements" do
      tree = parser.parse 'column=value'
      tree.wont_be_nil

      proposition = tree.proposition
      proposition.comparator.text_value.must_equal '='
      proposition.left.text_value.must_equal 'column'
      proposition.right.text_value.must_equal 'value'
    end

    describe 'Right hand Operand' do

      it 'must parse expression with integer' do
        tree = parser.parse 'column = 1'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::IntegerConstant
        right_hand_operand.value.must_equal 1
      end

      it 'must parse expression with float' do
        tree = parser.parse 'column = 2.3'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::FloatConstant
        right_hand_operand.value.must_equal 2.3
      end

      it 'must parse expression with true' do
        tree = parser.parse 'column = true'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::TrueConstant
        right_hand_operand.value.must_equal true
      end

      it 'must parse expression with false' do
        tree = parser.parse 'column = false'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::FalseConstant
        right_hand_operand.value.must_equal false
      end

      it 'must parse expression with string' do
        tree = parser.parse 'column = String1'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::StringConstant
        right_hand_operand.value.must_equal 'String1'
      end

      it 'must parse expression with literal string' do
        tree = parser.parse 'column = "a & (b | c) | d"'
        tree.wont_be_nil

        right_hand_operand = tree.proposition.right
        right_hand_operand.must_be_instance_of Rasti::DB::NQL::LiteralStringConstant
        right_hand_operand.value.must_equal 'a & (b | c) | d'
      end

      describe 'Time' do

        it 'must parse expression with hours and minutes' do
          tree = parser.parse 'column > 12:20'
          tree.wont_be_nil

          right_hand_operand = tree.proposition.right
          right_hand_operand.must_be_instance_of Rasti::DB::NQL::TimeConstant
          right_hand_operand.value.must_equal Timing::TimeInZone.parse('12:20')
        end

        it 'must parse expression with date, hours, minutes and seconds' do
          tree = parser.parse 'column > 2019-03-27T12:20:00'
          tree.wont_be_nil

          right_hand_operand = tree.proposition.right
          right_hand_operand.must_be_instance_of Rasti::DB::NQL::TimeConstant
          right_hand_operand.value.must_equal Timing::TimeInZone.parse('2019-03-27T12:20:00')
        end

        it 'must parse expression with date, hours, minutes, seconds and timezone' do
          tree = parser.parse 'column > 2019-03-27T12:20:00-03:00'
          tree.wont_be_nil

          right_hand_operand = tree.proposition.right
          right_hand_operand.must_be_instance_of Rasti::DB::NQL::TimeConstant
          right_hand_operand.value.must_equal Timing::TimeInZone.parse('2019-03-27T12:20:00-03:00')
        end

      end
    
    end

    it 'must parse expression with field with tables' do
      tree = parser.parse 'relation_table_one.relation_table_two.column = 1'
      tree.wont_be_nil

      left_hand_operand = tree.proposition.left
      left_hand_operand.tables.must_equal ['relation_table_one', 'relation_table_two']
      left_hand_operand.name.must_equal 'column'
    end

  end

  it 'must parse parenthesis sentence' do
    tree = parser.parse '(column: name)'
    tree.wont_be_nil

    tree.proposition.sentence.text_value.must_equal 'column: name'
  end

end