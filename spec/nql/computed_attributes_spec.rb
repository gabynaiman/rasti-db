require 'minitest_helper'

describe 'NQL::ComputedAttributes' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  def parse(expression)
    parser.parse expression
  end

  it 'must have one computed attributes' do
    tree = parse 'count_paragraphs() = 1'

    tree.computed_attributes.must_equal [:count_paragraphs]
  end

  it 'must have multiple computed attributes' do
    tree = parse 'count_paragraphs() = 1 & (body(): Hi | title() = good morning)'

    tree.computed_attributes.must_equal [:count_paragraphs, :body, :title]
  end

  it 'must have not repeated computed attributes when expression have it' do
    tree = parse 'body() = Hi | body() = Bye'

    tree.computed_attributes.must_equal [:body]
  end

end