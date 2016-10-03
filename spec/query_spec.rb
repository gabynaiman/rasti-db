require 'minitest_helper'

describe 'Query' do

  before do
    1.upto(10) { |i| db[:users].insert name: "User #{i}" }
    db[:posts].insert user_id: 2, title: 'Sample post', body: '...'
    db[:posts].insert user_id: 1, title: 'Another post', body: '...'
    db[:posts].insert user_id: 4, title: 'Best post', body: '...'
  end

  let(:users_query) { Rasti::DB::Query.new Users, db[:users] }

  let(:posts_query) { Rasti::DB::Query.new Posts, db[:posts] }

  it 'Count' do
    users_query.count.must_equal 10
  end

  it 'All' do
    users_query.all.must_equal db[:users].map { |u| User.new u }
  end

  it 'Map' do
    users_query.map { |u| u.name }.must_equal db[:users].map(:name)
  end

  it 'Where' do
    users_query.where(id: 3).all.must_equal [User.new(id: 3, name: 'User 3')]
  end
  
  it 'Exclude' do
    users_query.exclude(id: [1,2,3,4,5,6,7,8,9]).all.must_equal [User.new(id: 10, name: 'User 10')]
  end
  
  it 'And' do
    users_query.where(id: [1,2]).and(name: 'User 2').all.must_equal [User.new(id: 2, name: 'User 2')]
  end
  
  it 'Or' do
    users_query.where(id: 1).or(name: 'User 2').all.must_equal [
      User.new(id: 1, name: 'User 1'), 
      User.new(id: 2, name: 'User 2')
    ]
  end
  
  it 'Order' do
    posts_query.order(:title).all.must_equal [
      Post.new(id: 2, user_id: 1, title: 'Another post', body: '...'), 
      Post.new(id: 3, user_id: 4, title: 'Best post', body: '...'), 
      Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...')
    ]
  end
  
  it 'Reverse_order' do
    posts_query.reverse_order(:title).all.must_equal [
      Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...'),
      Post.new(id: 3, user_id: 4, title: 'Best post', body: '...'), 
      Post.new(id: 2, user_id: 1, title: 'Another post', body: '...')
    ]
  end
  
  it 'Limit and offset' do
    users_query.limit(1).offset(1).all.must_equal [User.new(id: 2, name: 'User 2')]
  end
  
  it 'First' do
    users_query.first.must_equal User.new(id: 1, name: 'User 1')
  end

  it 'Last' do
    users_query.order(:id).last.must_equal User.new(id: 10, name: 'User 10')
  end

  it 'Graph' do
    users_query.where(id: 1).graph(:posts).first.must_equal User.new(id: 1, name: 'User 1', posts: [Post.new(id: 2, user_id: 1, title: 'Another post', body: '...')])
  end

  it 'To String' do
    users_query.where(id: [1,2,3]).order(:name).to_s.must_equal '#<Rasti::DB::Query: "SELECT * FROM `users` WHERE (`id` IN (1, 2, 3)) ORDER BY `name`">'
  end

  describe 'Named queries' do

    it 'Respond to' do
      posts_query.must_respond_to :created_by
      posts_query.wont_respond_to :by_user
    end

    it 'Safe method missing' do
      posts_query.created_by(1).first.must_equal Post.new(db[:posts][user_id: 1])
      proc { posts_query.by_user(1) }.must_raise NoMethodError
    end

  end

end