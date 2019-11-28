require 'minitest_helper'

describe 'NQL::FilterCondition' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  def filter_condition(expression)
    tree = parser.parse expression
    tree.filter_condition
  end

  def assert_identifier(identifier, expected_value)
    identifier.must_be_instance_of Sequel::SQL::Identifier
    identifier.value.must_equal expected_value
  end

  def assert_comparison(filter, expected_left, expected_comparator, expected_right)
    filter.must_be_instance_of Sequel::SQL::BooleanExpression
    filter.op.must_equal expected_comparator.to_sym
    
    left, right = filter.args
    assert_identifier left, expected_left

    right.must_equal expected_right
  end

  describe 'Comparison' do

    it 'must create filter from expression with <' do
      splitted_expression = ['column', '<', 1]

      assert_comparison filter_condition(splitted_expression.join(' ')), *splitted_expression
    end

    it 'must create filter from expression with >' do
      splitted_expression = ['column', '>', 1]

      assert_comparison filter_condition(splitted_expression.join(' ')), *splitted_expression
    end

    it 'must create filter from expression with <=' do
      splitted_expression = ['column', '<=', 1]

      assert_comparison filter_condition(splitted_expression.join(' ')), *splitted_expression
    end

    it 'must create filter from expression with >=' do
      splitted_expression = ['column', '>=', 1]

      assert_comparison filter_condition(splitted_expression.join(' ')), *splitted_expression
    end

    it 'must create filter from expression with !=' do
      splitted_expression = ['column', '!=', 1]

      assert_comparison filter_condition(splitted_expression.join(' ')), *splitted_expression
    end

    it 'must create filter from expression with =' do
      filter = filter_condition 'column = 1'
      identifier, value = filter.first

      assert_identifier identifier, 'column'
      value.must_equal 1
    end

    it 'must create filter from expression with ~' do
      filter = filter_condition 'column ~ test'
      assert_comparison filter, 'column', 'ILIKE', 'test'
    end

    it 'must create filter from expression with :' do
      filter = filter_condition 'column: test'
      assert_comparison filter, 'column', 'ILIKE', '%test%'
    end

    it 'must create filter from expression with !:' do
      filter = filter_condition 'column!: test'
      assert_comparison filter, 'column', 'NOT ILIKE', '%test%'
    end

  end

  describe 'Constants' do

    it 'must create filter from expression with LiteralString' do
      filter = filter_condition 'column: "test "'
      assert_comparison filter, 'column', 'ILIKE', '%test %'
    end

    it 'must create filter from expression with Time' do
      filter = filter_condition 'column > 2019-03-27T12:20:00-03:00'
      assert_comparison filter, 'column', '>', '2019-03-27 12:20:00 -0300'
    end

  end

  it 'must create filter from expression with field with multiple tables' do
    filter = filter_condition 'table_one.table_two.column = test'
    identifier, value = filter.first

    identifier.must_be_instance_of Sequel::SQL::QualifiedIdentifier
    identifier.table.must_equal 'table_one__table_two'
    identifier.column.must_equal :column
    value.must_equal 'test'
  end

  it 'must create filter from expression with conjunction' do
    filter = filter_condition 'column_one > 1 & column_two < 3'

    filter.must_be_instance_of Sequel::SQL::BooleanExpression
    filter.op.must_equal :AND
    major_expression, minor_expression = filter.args

    assert_comparison major_expression, 'column_one', '>', 1
    assert_comparison minor_expression, 'column_two', '<', 3
  end

  it 'must create filter from expression with disjunction' do
    filter = filter_condition 'column_one > 1 | column_two != 3'

    filter.must_be_instance_of Sequel::SQL::BooleanExpression
    filter.op.must_equal :OR
    major_expression, not_equal_expression = filter.args

    assert_comparison major_expression, 'column_one', '>', 1
    assert_comparison not_equal_expression, 'column_two', '!=', 3
  end

  it 'must create filter from expression with parenthesis' do
    filter = filter_condition 'column_one > 1 & (column_two != 3 | column_three < 5)'

    filter.must_be_instance_of Sequel::SQL::BooleanExpression
    filter.op.must_equal :AND
    
    major_expression, and_expression = filter.args
    assert_comparison major_expression, 'column_one', '>', 1

    and_expression.op.must_equal :OR
    not_equal_expression, minor_expression = and_expression.args

    assert_comparison not_equal_expression, 'column_two', '!=', 3
    assert_comparison minor_expression, 'column_three', '<', 5
  end

end