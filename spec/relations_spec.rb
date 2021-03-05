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

    it 'Type' do
      relation = Rasti::DB::Relations::OneToMany.new :posts, Users

      relation.one_to_many?.must_equal true
      relation.many_to_one?.must_equal false
      relation.many_to_many?.must_equal false
      relation.one_to_one?.must_equal false

      relation.from_one?.must_equal true
      relation.from_many?.must_equal false
      relation.to_one?.must_equal false
      relation.to_many?.must_equal true
    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'
      1.upto(2) { |i| db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...', language_id: 1 }
      rows = db[:users].all

      Users.relations[:posts].fetch_graph environment, rows

      rows[0][:posts].must_equal posts.where(user_id: user_id).all
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

    it 'Type' do
      relation = Rasti::DB::Relations::ManyToOne.new :user, Posts

      relation.one_to_many?.must_equal false
      relation.many_to_one?.must_equal true
      relation.many_to_many?.must_equal false
      relation.one_to_one?.must_equal false

      relation.from_one?.must_equal false
      relation.from_many?.must_equal true
      relation.to_one?.must_equal true
      relation.to_many?.must_equal false
    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'
      db[:posts].insert user_id: user_id, title: 'Post 1', body: '...', language_id: 1
      rows = db[:posts].all

      Posts.relations[:user].fetch_graph environment, rows

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

    it 'Type' do
      relation = Rasti::DB::Relations::ManyToMany.new :categories, Posts

      relation.one_to_many?.must_equal false
      relation.many_to_one?.must_equal false
      relation.many_to_many?.must_equal true
      relation.one_to_one?.must_equal false

      relation.from_one?.must_equal false
      relation.from_many?.must_equal true
      relation.to_one?.must_equal false
      relation.to_many?.must_equal true
    end

    it 'Graph' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(2) { |i| db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...', language_id: 1 }

      1.upto(4) { |i| db[:categories].insert name: "Category #{i}" }

      db[:categories_posts].insert post_id: 1, category_id: 1
      db[:categories_posts].insert post_id: 1, category_id: 2
      db[:categories_posts].insert post_id: 2, category_id: 3
      db[:categories_posts].insert post_id: 2, category_id: 4

      rows = db[:posts].all

      Posts.relations[:categories].fetch_graph environment, rows

      rows[0][:categories].must_equal categories.where(id: [1,2]).all
      rows[1][:categories].must_equal categories.where(id: [3,4]).all
    end

  end

  describe 'One To One' do

    describe 'Specification' do

      it 'Implicit' do
        relation = Rasti::DB::Relations::OneToOne.new :person, Users

        relation.target_collection_class.must_equal People
        relation.foreign_key.must_equal :user_id
      end

      it 'Explicit' do
        relation = Rasti::DB::Relations::OneToOne.new :person, Users, collection: 'Users',
                                                                      foreign_key: :id_user

        relation.target_collection_class.must_equal Users
        relation.foreign_key.must_equal :id_user
      end

    end

    it 'Type' do
      relation = Rasti::DB::Relations::OneToOne.new :person, User

      relation.one_to_many?.must_equal false
      relation.many_to_one?.must_equal false
      relation.many_to_many?.must_equal false
      relation.one_to_one?.must_equal true

      relation.from_one?.must_equal true
      relation.from_many?.must_equal false
      relation.to_one?.must_equal true
      relation.to_many?.must_equal false
    end

    it 'Graph' do
      2.times do |i|
        user_id = db[:users].insert name: "User #{i}"
        db[:people].insert document_number: "document_#{i}",
                           first_name: "John #{i}",
                           last_name: "Doe #{i}",
                           birth_date: Time.now - i,
                           user_id: user_id
      end

      rows = db[:users].all

      Users.relations[:person].fetch_graph environment, rows

      2.times do |i|
        rows[i][:person].must_equal people.find("document_#{i}")
      end
    end

  end

end