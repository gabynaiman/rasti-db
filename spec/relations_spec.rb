require 'minitest_helper'

describe 'Relations' do

  describe 'One to Many' do

    describe 'Specification' do

      it 'Implicit' do
        relation = Rasti::DB::Relations::OneToMany.new :posts, Users
        
        relation.target_collection_class.must_equal Posts
        relation.foreign_key.must_equal :user_id
      end

      it 'Explicit' do
        relation = Rasti::DB::Relations::OneToMany.new :articles, Users, collection: 'Posts', 
                                                                         foreign_key: :id_user
        
        relation.target_collection_class.must_equal Posts
        relation.foreign_key.must_equal :id_user
      end

    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'
      1.upto(2) { |i| db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...' }
      rows = db[:users].all
      
      Users.relations[:posts].graph_to rows, db
      
      rows[0][:posts].must_equal posts.query { where user_id: user_id }
    end

  end

  describe 'Many to One' do

    describe 'Specification' do

      it 'Implicit' do
        relation = Rasti::DB::Relations::ManyToOne.new :user, Posts
        
        relation.target_collection_class.must_equal Users
        relation.foreign_key.must_equal :user_id
      end

      it 'Explicit' do
        relation = Rasti::DB::Relations::ManyToOne.new :publisher, Posts, collection: 'Users', 
                                                                          foreign_key: :publisher_id
        
        relation.target_collection_class.must_equal Users
        relation.foreign_key.must_equal :publisher_id
      end

    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'
      db[:posts].insert user_id: user_id, title: 'Post 1', body: '...'
      rows = db[:posts].all

      Posts.relations[:user].graph_to rows, db

      rows[0][:user].must_equal users.first
    end

  end

  describe 'Many To Many' do

    describe 'Specification' do

      it 'Implicit' do
        relation = Rasti::DB::Relations::ManyToMany.new :categories, Posts
        
        relation.target_collection_class.must_equal Categories
        relation.source_foreign_key.must_equal :post_id
        relation.target_foreign_key.must_equal :category_id
        relation.relation_collection_name.must_equal :categories_posts
      end

      it 'Explicit' do
        relation = Rasti::DB::Relations::ManyToMany.new :tags, Posts, collection: 'Categories', 
                                                                      source_foreign_key: :article_id, 
                                                                      target_foreign_key: :tag_id, 
                                                                      relation_collection_name: :tags_articles
        
        relation.target_collection_class.must_equal Categories
        relation.source_foreign_key.must_equal :article_id
        relation.target_foreign_key.must_equal :tag_id
        relation.relation_collection_name.must_equal :tags_articles
      end

    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(2) { |i| db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...' }

      1.upto(4) { |i| db[:categories].insert name: "Category #{i}" }

      db[:categories_posts].insert post_id: 1, category_id: 1
      db[:categories_posts].insert post_id: 1, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 3
      db[:categories_posts].insert post_id: 2, category_id: 4

      rows = db[:posts].all

      Posts.relations[:categories].graph_to rows, db

      rows[0][:categories].must_equal categories.query { where id: [1,2] }
      rows[1][:categories].must_equal categories.query { where id: [3,4] }
    end

  end

end