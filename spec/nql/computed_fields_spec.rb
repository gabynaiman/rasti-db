require 'minitest_helper'

describe 'NQL::ComputedFields' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  def parse(expression)
    parser.parse expression
  end

  it 'must have one computed fields' do
    tree = parse 'count_paragraphs() = 1'

    tree.computed_fields.must_equal [:count_paragraphs]
  end

  it 'must have multiple computed fields' do
    tree = parse 'count_paragraphs() = 1 & (body(): Hi | title() = good morning)'

    tree.computed_fields.must_equal [:count_paragraphs, :body, :title]
  end

  it 'must have not repeated computed fields when expression have it' do
    tree = parse 'body() = Hi | body() = Bye'

    tree.computed_fields.must_equal [:body]
  end

end