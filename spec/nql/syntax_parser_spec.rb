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

    end
  end
end