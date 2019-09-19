require 'minitest_helper'

describe 'SyntaxParser' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  describe 'Comparison' do

    ['>=', '<=', '>' , '<' , '!=', '=' , ':' , '!:', '~'].each do |comparator|
      expression = "column #{comparator} 1"
      test_name = "must parse '#{expression}'"

      it test_name do
        tree = parser.parse expression
        tree.wont_be_nil

        sentence = tree.sentence
        sentence.comparator.text_value.must_equal comparator
        sentence.left.text_value.must_equal 'column'
        sentence.right.text_value.must_equal '1'
      end
    end

    it "must parse without spaces between elements" do
      tree = parser.parse 'column:1'
      tree.wont_be_nil

      sentence = tree.sentence
      sentence.comparator.text_value.must_equal ':'
      sentence.left.text_value.must_equal 'column'
      sentence.right.text_value.must_equal '1'
    end

    describe 'Right hand operand' do

      it "must parse 1 as Integer" do
        tree = parser.parse 'column = 1'
        tree.wont_be_nil

        right_operand = tree.sentence.right
        right_operand.must_be_instance_of Rasti::DB::NQL::IntegerConstant
        right_operand.text_value.must_equal '1'
        right_operand.value.must_equal 1
      end



    end

  end

end