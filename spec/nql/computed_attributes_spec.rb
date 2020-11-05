require 'minitest_helper'

describe 'NQL::ComputedAttributes' do

  let(:parser) { Rasti::DB::NQL::SyntaxParser.new }

  def parse(expression)
    parser.parse expression
  end

  it 'must have one computed attributes' do
    tree = parse 'notice = any notice'

    tree.computed_attributes(Posts).must_equal [:notice]
  end

  it 'must have multiple computed attributes' do
    tree = parse 'notice = any notice & (author: anonym | title = good morning)'

    tree.computed_attributes(Posts).must_equal [:notice, :author]
  end

  it 'must have not repeated computed attributes when expression have it' do
    tree = parse 'notice = Hi | notice = Bye'

    tree.computed_attributes(Posts).must_equal [:notice]
  end

end