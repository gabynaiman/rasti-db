require 'minitest_helper'

describe 'NQL::DepedencyTables' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  def parse(expression)
    parser.parse expression
  end

  it 'must have no dependency tables' do
    tree = parse 'column = 1'

    tree.dependency_tables.must_be_empty
  end

  it 'must have one dependency table' do
    tree = parse 'relation_table_one.relation_table_two.column = 1'

    tree.dependency_tables.must_equal ['relation_table_one.relation_table_two']
  end

  it 'must have multiple dependency tables' do
    tree = parse 'a.b.c = 1 & (d.e: 2 | f.g.h = 1) | i = 4'

    tree.dependency_tables.must_equal ['a.b', 'd', 'f.g']
  end

  it 'must have repeated sub-dependency' do
    tree = parse 'a.b.c = 1 & a.d: 2'

    tree.dependency_tables.must_equal ['a.b', 'a']
  end

end