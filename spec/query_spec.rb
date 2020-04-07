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
  
  let(:comments_query) { Rasti::DB::Query.new Comments, db[:comments] }

  it 'Count' do
    users_query.count.must_equal 10
  end

  it 'All' do
    users_query.all.must_equal db[:users].map { |u| User.new u }
  end

  it 'Raw' do
    users_query.raw.must_equal db[:users].all
  end

  it 'Pluck' do
    users_query.pluck(:name).must_equal db[:users].map { |u| u[:name] }
    users_query.pluck(:id, :name).must_equal db[:users].map { |u| [u[:id], u[:name]] }
  end

  it 'Primary keys' do
    users_query.primary_keys.must_equal db[:users].map { |u| u[:id] }
  end

  it 'Map' do
    users_query.map(&:name).must_equal db[:users].map(:name)
  end

  it 'Detect' do
    users_query.detect(id: 3).must_equal User.new(id: 3, name: 'User 3')
  end

  it 'Where' do
    users_query.where(id: 3).all.must_equal [User.new(id: 3, name: 'User 3')]
  end
  
  it 'Exclude' do
    users_query.exclude(id: [1,2,3,4,5,6,7,8,9]).all.must_equal [User.new(id: 10, name: 'User 10')]
  end
  
  it 'And' do
    users_query.where(id: [1,2]).where(name: 'User 2').all.must_equal [User.new(id: 2, name: 'User 2')]
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
  
  it 'Reverse order' do
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
    users_query.graph(:posts).where(id: 1).first.must_equal User.new(id: 1, name: 'User 1', posts: [Post.new(id: 2, user_id: 1, title: 'Another post', body: '...')])
  end

  it 'Empty?' do
    users_query.empty?.must_equal false
    users_query.any?.must_equal true
  end

  it 'Any?' do
    comments_query.empty?.must_equal true
    comments_query.any?.must_equal false
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

  describe 'Join' do

    before do
      1.upto(10) do |i| 
        db[:people].insert user_id: i, 
                           document_number: i, 
                           first_name: "Name #{i}", 
                           last_name: "Last Name #{i}", 
                           birth_date: Time.now
      end

      1.upto(3) { |i| db[:categories].insert name: "Category #{i}" }
      
      db[:comments].insert post_id: 1, user_id: 5, text: 'Comment 1'
      db[:comments].insert post_id: 1, user_id: 7, text: 'Comment 2'
      db[:comments].insert post_id: 2, user_id: 2, text: 'Comment 3'

      db[:categories_posts].insert post_id: 1, category_id: 1
      db[:categories_posts].insert post_id: 1, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 3
      db[:categories_posts].insert post_id: 3, category_id: 3
    end

    it 'One to Many' do
      users_query.join(:posts).where(title: 'Sample post').all.must_equal [User.new(id: 2, name: 'User 2')]
    end

    it 'Many to One' do
      posts_query.join(:user).where(name: 'User 4').all.must_equal [Post.new(id: 3, user_id: 4, title: 'Best post', body: '...')]
    end

    it 'One to One' do
      users_query.join(:person).where(document_number: 1).all.must_equal [User.new(id: 1, name: 'User 1')]
    end

    it 'Many to Many' do
      posts_query.join(:categories).where(name: 'Category 3').order(:id).all.must_equal [
        Post.new(id: 2, user_id: 1, title: 'Another post', body: '...'),
        Post.new(id: 3, user_id: 4, title: 'Best post', body: '...'),
      ]
    end

    it 'Nested' do
      posts_query.join('categories', 'comments.user.person')
                 .where(Sequel[:categories][:name] => 'Category 2')
                 .where(Sequel[:comments__user__person][:document_number] => 7)
                 .all
                 .must_equal [Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...')]
    end

  end

  describe 'NQL' do

    before do
      1.upto(10) do |i| 
        db[:people].insert user_id: i, 
                           document_number: i, 
                           first_name: "Name #{i}", 
                           last_name: "Last Name #{i}", 
                           birth_date: Time.now
      end

      1.upto(3) { |i| db[:categories].insert name: "Category #{i}" }
      
      db[:comments].insert post_id: 1, user_id: 5, text: 'Comment 1'
      db[:comments].insert post_id: 1, user_id: 7, text: 'Comment 2'
      db[:comments].insert post_id: 2, user_id: 2, text: 'Comment 3'

      db[:categories_posts].insert post_id: 1, category_id: 1
      db[:categories_posts].insert post_id: 1, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 3
      db[:categories_posts].insert post_id: 3, category_id: 3
    end

    it 'Invalid expression' do
      error = proc { posts_query.nql('a + b') }.must_raise Rasti::DB::NQL::InvalidExpressionError
      error.message.must_equal 'Invalid filter expression: a + b'
    end
    
    it 'Filter to self table' do
      posts_query.nql('user_id > 1')
                  .map(&:user_id)
                  .sort
                  .must_equal [2, 4]
    end

    it 'Filter to join table' do
      posts_query.nql('categories.name = Category 2')
                 .map(&:id)
                 .sort
                 .must_equal [1, 2]
    end

    it 'Filter to 2nd order relation' do
      posts_query.nql('comments.user.person.document_number = 7')
                 .map(&:id)
                 .must_equal [1]
    end

  end

end