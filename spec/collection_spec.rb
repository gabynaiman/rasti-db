require 'minitest_helper'

describe 'Collection' do

  describe 'Specification' do

    it 'Implicit' do
      Users.collection_name.must_equal :users
      Users.model.must_equal User
      Users.primary_key.must_equal :id
      Users.implicit_foreign_key_name.must_equal :user_id
    end

    it 'Explicit' do
      model_class = Rasti::DB::Model[:code, :name]
      
      collection_class = Class.new(Rasti::DB::Collection) do
        set_collection_name :countries
        set_primary_key :code
        set_model model_class
      end

      collection_class.collection_name.must_equal :countries
      collection_class.model.must_equal model_class
      collection_class.primary_key.must_equal :code
    end

  end

  describe 'Insert, Update and Delete' do

    it 'Insert' do
      id = users.insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'
    end

    it 'Insert many to many' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(2) do |i| 
        db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...'
        db[:categories].insert name: "Category #{i}"
      end

      post_id = posts.insert user_id: user_id, title: 'Post title', body: '...', categories: [1,2]
      category_id = categories.insert name: 'Category', posts: [1,2]

      db[:categories_posts].where(post_id: post_id).map(:category_id).must_equal [1,2]
      db[:categories_posts].where(category_id: category_id).map(:post_id).must_equal [1,2]
    end

    it 'Insert batch'

    it 'Update' do
      id = db[:users].insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'

      users.update id, name: 'updated'

      db[:users][id: id][:name].must_equal 'updated'
    end

    it 'Update many to many' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(3) do |i| 
        db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...'
        db[:categories].insert name: "Category #{i}"
      end

      db[:categories_posts].insert post_id: 1, category_id: 1
      db[:categories_posts].insert post_id: 1, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 2

      db[:categories_posts].where(post_id: 1).map(:category_id).must_equal [1,2]

      posts.update 1, categories: [2,3]

      db[:categories_posts].where(post_id: 1).map(:category_id).must_equal [2,3]
      
      db[:categories_posts].where(category_id: 2).map(:post_id).must_equal [1,2]

      categories.update 2, posts: [2,3]
      
      db[:categories_posts].where(category_id: 2).map(:post_id).must_equal [2,3]
    end

    it 'Update batch'

    it 'Delete' do
      id = db[:users].insert name: 'User 1'

      db[:users].count.must_equal 1

      users.delete id

      db[:users].count.must_equal 0
    end

    it 'Delete batch'

  end

  describe 'Queries' do

    it 'Find' do
      id = db[:users].insert name: 'User 1'
      
      users.find(id).must_equal User.new(id: id, name: 'User 1')
    end

    it 'Count' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.count.must_equal 10
    end

    it 'All' do
      id = db[:users].insert name: 'User 1'

      users.all.must_equal [User.new(id: id, name: 'User 1')]
    end

    it 'First' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.first.must_equal User.new(id: 1, name: 'User 1')
    end

    it 'Query' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      models = users.query { where(id: [1,2]).reverse_order(:id) }

      models.must_equal [2,1].map { |i| User.new(id: i, name: "User #{i}") }
    end

    it 'Graph' do
      1.upto(3) do |i|
        db[:users].insert name: "User #{i}"
        db[:categories].insert name: "Category #{i}"
        db[:posts].insert user_id: i, title: "Post #{i}", body: '...'
        db[:categories_posts].insert post_id: i, category_id: i
      end

      db[:posts].map(:id).each do |post_id|
        db[:users].map(:id).each do |user_id|
          db[:comments].insert post_id: post_id, user_id: user_id, text: 'Comment'
        end
      end

      posts_graph = posts.query { where(id: 1).graph :user, :categories, 'comments.user.posts.categories' }

      posts_graph.count.must_equal 1

      posts_graph[0].user.must_equal users.find(1)

      posts_graph[0].categories.must_equal [categories.find(1)]

      posts_graph[0].comments.count.must_equal 3
      posts_graph[0].comments.each_with_index do |comment, index|
        i = index + 1

        comment.post_id.must_equal 1
        comment.user_id.must_equal i
        
        comment.user.id.must_equal i
        comment.user.name.must_equal "User #{i}"
        
        comment.user.posts.count.must_equal 1
        comment.user.posts[0].id.must_equal i
        comment.user.posts[0].title.must_equal "Post #{i}"
        comment.user.posts[0].user_id.must_equal i

        comment.user.posts[0].categories.count.must_equal 1
        comment.user.posts[0].categories[0].id.must_equal i
        comment.user.posts[0].categories[0].name.must_equal "Category #{i}"
      end
    end

  end

  describe 'Schemas' do

    let :stub_db do
      stubs = Proc.new do |sql|
        case sql

        when 'SELECT * FROM custom_schema.users', 
             'SELECT * FROM custom_schema.users WHERE (id IN (2, 1))'
          [
            {id: 1},
            {id: 2}
          ]

        when 'SELECT * FROM custom_schema.posts',
             'SELECT * FROM custom_schema.posts WHERE (user_id IN (1, 2))'
          [
            {id: 3, user_id: 1},
            {id: 4, user_id: 2}
          ]

        when 'SELECT * FROM custom_schema.comments WHERE (post_id IN (3, 4))'
          [
            {id: 5, user_id: 2, post_id: 3},
            {id: 6, user_id: 1, post_id: 3},
            {id: 7, user_id: 1, post_id: 4},
            {id: 8, user_id: 2, post_id: 4}
          ]

        else
          nil
        end
      end

      Sequel.mock fetch: stubs, autoid: 1
    end

    let(:stub_users) { Users.new stub_db, :custom_schema }
    let(:stub_posts) { Posts.new stub_db, :custom_schema }

    it 'Insert' do
      stub_users.insert name: 'User 1'
      stub_db.sqls.must_equal [
        'BEGIN',
        "INSERT INTO custom_schema.users (name) VALUES ('User 1')",
        'COMMIT'
      ]
    end

    it 'Insert with many to many relation' do
      stub_posts.insert user_id: 1, title: 'Post 1', body: '...', categories: [2,3]
      stub_db.sqls.must_equal [
        'BEGIN',
        "INSERT INTO custom_schema.posts (user_id, title, body) VALUES (1, 'Post 1', '...')",
        'DELETE FROM custom_schema.categories_posts WHERE (post_id = 1)',
        'INSERT INTO custom_schema.categories_posts (post_id, category_id) VALUES (1, 2)',
        'INSERT INTO custom_schema.categories_posts (post_id, category_id) VALUES (1, 3)',
        'COMMIT'
      ]
    end

    it 'Update' do
      stub_users.update 1, name: 'Updated name'
      stub_db.sqls.must_equal [
        'BEGIN',
        "UPDATE custom_schema.users SET name = 'Updated name' WHERE (id = 1)",
        'COMMIT'
      ]
    end

    it 'Delete' do
      stub_users.delete 1
      stub_db.sqls.must_equal ['DELETE FROM custom_schema.users WHERE (id = 1)']
    end

    it 'Query' do
      stub_users.query { where(id: [1,2]).limit(1).order(:name) }
      stub_db.sqls.must_equal ['SELECT * FROM custom_schema.users WHERE (id IN (1, 2)) ORDER BY name LIMIT 1']
    end

    it 'Graph' do
      stub_posts.query { graph :user, :categories, 'comments.user.posts.categories' }
      stub_db.sqls.must_equal [
        'SELECT * FROM custom_schema.posts',
        'SELECT * FROM custom_schema.users WHERE (id IN (1, 2))',
        'SELECT * FROM custom_schema.categories INNER JOIN custom_schema.categories_posts ON (custom_schema.categories_posts.category_id = custom_schema.categories.id) WHERE (custom_schema.categories_posts.post_id IN (3, 4))', 
        'SELECT * FROM custom_schema.comments WHERE (post_id IN (3, 4))',
        'SELECT * FROM custom_schema.users WHERE (id IN (2, 1))',
        'SELECT * FROM custom_schema.posts WHERE (user_id IN (1, 2))',
        'SELECT * FROM custom_schema.categories INNER JOIN custom_schema.categories_posts ON (custom_schema.categories_posts.category_id = custom_schema.categories.id) WHERE (custom_schema.categories_posts.post_id IN (3, 4))'
      ]
    end

  end

end