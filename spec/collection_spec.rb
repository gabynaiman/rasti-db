require 'minitest_helper'

describe 'Collection' do

  before do
    Rasti::DB.type_converters = [Rasti::DB::TypeConverters::TimeInZone]
  end

  after do
    Rasti::DB.type_converters = [Rasti::DB::TypeConverters::TimeInZone, Rasti::DB::TypeConverters::SQLite]
  end

  describe 'Specification' do

    it 'Implicit' do
      Users.collection_name.must_equal :users
      Users.collection_attributes.must_equal [:id, :name]
      Users.model.must_equal User
      Users.primary_key.must_equal :id
      Users.foreign_key.must_equal :user_id
      Users.data_source_name.must_equal :default
    end

    it 'Explicit' do
      People.collection_name.must_equal :people
      People.collection_attributes.must_equal [:document_number, :first_name, :last_name, :birth_date, :user_id]
      People.model.must_equal Person
      People.primary_key.must_equal :document_number
      People.foreign_key.must_equal :document_number

      Languages.data_source_name.must_equal :custom
    end

    it 'Lazy model name' do
      collection_class = Class.new(Rasti::DB::Collection) do
        set_model :User
      end

      collection_class.model.must_equal User
    end

  end

  describe 'Insert, Update and Delete' do

    it 'Insert' do
      id = users.insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'
    end

    it 'Insert with many to many' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(2) do |i|
        db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...', language_id: 1
        db[:categories].insert name: "Category #{i}"
      end

      post_id = posts.insert user_id: user_id, title: 'Post title', body: '...', categories: [1,2], language_id: 1
      category_id = categories.insert name: 'Category', posts: [1,2]

      db[:categories_posts].where(post_id: post_id).map(:category_id).must_equal [1,2]
      db[:categories_posts].where(category_id: category_id).map(:post_id).must_equal [1,2]
    end

    it 'Insert only many to many' do
      1.upto(3) do |i|
        db[:categories].insert name: "Category #{i}"
      end

      user_id = db[:users].insert name: 'User 1'
      post_id = db[:posts].insert user_id: user_id, title: 'Post title', body: '...', language_id: 1
      1.upto(2) { |category_id| db[:categories_posts].insert post_id: post_id, category_id: category_id }

      posts.insert_relations post_id, categories: [3]

      db[:categories_posts].where(post_id: post_id).map(:category_id).must_equal [1,2,3]
    end

    it 'Bulk insert' do
      users_attrs = 1.upto(2).map { |i| {name: "User #{i}"} }

      ids = users.bulk_insert users_attrs, return: :primary_key

      ids.must_equal [1,2]
      db[:users][id: 1][:name].must_equal 'User 1'
      db[:users][id: 2][:name].must_equal 'User 2'
    end

    it 'Update' do
      id = db[:users].insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'

      users.update id, name: 'updated'

      db[:users][id: id][:name].must_equal 'updated'
    end

    it 'Update with many to many' do
      user_id = db[:users].insert name: 'User 1'

      1.upto(3) do |i|
        db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...', language_id: 1
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

    it 'Bulk update' do
      user_id = db[:users].insert name: 'User 1'
      1.upto(3) { |i| db[:posts].insert user_id: user_id, title: "Post #{i}", body: '...', language_id: 1 }

      posts.bulk_update(body: 'Updated ...') { where id: [1,2] }

      db[:posts][id: 1][:body].must_equal 'Updated ...'
      db[:posts][id: 2][:body].must_equal 'Updated ...'
      db[:posts][id: 3][:body].must_equal '...'
    end

    it 'Delete' do
      id = db[:users].insert name: 'User 1'

      db[:users].count.must_equal 1

      users.delete id

      db[:users].count.must_equal 0
    end

    it 'Delete only many to many' do
      1.upto(3) do |i|
        db[:categories].insert name: "Category #{i}"
      end

      user_id = db[:users].insert name: 'User 1'
      post_id = db[:posts].insert user_id: user_id, title: 'Post title', body: '...', language_id: 1
      1.upto(3) { |category_id| db[:categories_posts].insert post_id: post_id, category_id: category_id }

      posts.delete_relations post_id, categories: [3]

      db[:categories_posts].where(post_id: post_id).map(:category_id).must_equal [1,2]
    end

    it 'Bulk delete' do
      1.upto(3) { |i| db[:users].insert name: "User #{i}" }

      users.bulk_delete { where id: [1,2] }

      db[:users].map(:id).must_equal [3]
    end

    describe 'Delete cascade' do

      before :each do
        1.upto(3) do |i|
          user_id = db[:users].insert name: "User #{i}"

          db[:people].insert document_number: "document_#{i}",
                             first_name: "John #{i}",
                             last_name: "Doe #{i}",
                             birth_date: Time.now - i,
                             user_id: user_id

          category_id = db[:categories].insert name: "Category #{i}"

          1.upto(3) do |n|
            post_id = db[:posts].insert user_id: user_id, title: "Post #{i}.#{n}", body: '...', language_id: 1
            db[:categories_posts].insert post_id: post_id, category_id: category_id
          end
        end

        {1 => 4..6, 2 => 7..9, 3 => 1..3}.each do |user_id, post_ids|
          post_ids.each do |post_id|
            db[:comments].insert post_id: post_id, user_id: user_id, text: 'Comment'
          end
        end
      end

      it 'Self relations' do
        db[:posts].where(id: 1).count.must_equal 1
        db[:categories_posts].where(post_id: 1).count.must_equal 1
        db[:comments].where(post_id: 1).count.must_equal 1

        posts.delete_cascade 1

        db[:posts].where(id: 1).count.must_equal 0
        db[:categories_posts].where(post_id: 1).count.must_equal 0
        db[:comments].where(post_id: 1).count.must_equal 0

        db[:users].count.must_equal 3
        db[:categories].count.must_equal 3
        db[:posts].count.must_equal 8
        db[:categories_posts].count.must_equal 8
        db[:comments].count.must_equal 8
      end

      it 'Deep relations' do
        db[:users].where(id: 1).count.must_equal 1
        db[:people].where(user_id: 1).count.must_equal 1
        db[:comments].where(user_id: 1).count.must_equal 3
        db[:posts].where(user_id: 1).count.must_equal 3
        db[:comments].join(:posts, id: :post_id).where(Sequel[:posts][:user_id] => 1).count.must_equal 3
        db[:categories_posts].join(:posts, id: :post_id).where(Sequel[:posts][:user_id] => 1).count.must_equal 3

        users.delete_cascade 1

        db[:users].where(id: 1).count.must_equal 0
        db[:people].where(user_id: 1).count.must_equal 0
        db[:comments].where(user_id: 1).count.must_equal 0
        db[:posts].where(user_id: 1).count.must_equal 0
        db[:comments].join(:posts, id: :post_id).where(Sequel[:posts][:user_id] => 1).count.must_equal 0
        db[:categories_posts].join(:posts, id: :post_id).where(Sequel[:posts][:user_id] => 1).count.must_equal 0

        db[:users].count.must_equal 2
        db[:people].count.must_equal 2
        db[:categories].count.must_equal 3
        db[:posts].count.must_equal 6
        db[:categories_posts].count.must_equal 6
        db[:comments].count.must_equal 3
      end

    end

    describe 'Multiple data sources' do

      before do
        1.upto(3) do |i|
          db[:users].insert name: "User #{i}"
          db[:people].insert document_number: "document_#{i}",
                             first_name: "John #{i}",
                             last_name: "Doe #{i}",
                             birth_date: Time.now - i,
                             user_id: i
        end
      end

      it 'Insert' do
        id = languages.insert name: 'Spanish', people: ['document_1', 'document_2']

        custom_db[:languages][id: id][:name].must_equal 'Spanish'
        db[:languages_people].where(language_id: id).select_map(:document_number).must_equal ['document_1', 'document_2']
      end

      it 'Update' do
        id = custom_db[:languages].insert name: 'Spanish'
        db[:languages_people].insert language_id: id, document_number: 'document_1'

        custom_db[:languages][id: id][:name].must_equal 'Spanish'
        db[:languages_people].where(language_id: id).select_map(:document_number).must_equal ['document_1']

        languages.update id, name: 'English', people: ['document_2', 'document_3']

        custom_db[:languages][id: id][:name].must_equal 'English'
        db[:languages_people].where(language_id: id).select_map(:document_number).must_equal ['document_2', 'document_3']
      end

      it 'Delete' do
        id = custom_db[:languages].insert name: 'Spanish'
        db[:languages_people].insert language_id: id, document_number: 'document_1'
        db[:posts].insert user_id: 1, title: 'Post 1', body: '...', language_id: id

        languages.delete id

        custom_db[:languages].count.must_equal 0
        db[:languages_people].where(language_id: id).count.must_equal 1
        db[:posts].where(language_id: id).count.must_equal 1
      end

      it 'Delete cascade' do
        id = custom_db[:languages].insert name: 'Spanish'
        db[:languages_people].insert language_id: id, document_number: 'document_1'
        db[:posts].insert user_id: 1, title: 'Post 1', body: '...', language_id: id

        languages.delete_cascade id

        custom_db[:languages].count.must_equal 0
        db[:languages_people].where(language_id: id).count.must_equal 0
        db[:posts].where(language_id: id).count.must_equal 0
      end

    end

  end

  describe 'Queries' do

    it 'Find' do
      id = db[:users].insert name: 'User 1'

      users.find(id).must_equal User.new(id: id, name: 'User 1')
    end

    it 'Find graph' do
      user_id = db[:users].insert name: 'User 1'
      db[:posts].insert user_id: user_id, title: 'Post 1', body: '...', language_id: 1

      users.find_graph(user_id, :posts).must_equal User.new id: user_id, name: 'User 1', posts: posts.all
    end

    it 'Select attributes' do
      id = db[:users].insert name: 'User 1'

      users.select_attributes(:id).all.must_equal [User.new(id: id)]
    end

    it 'Exclude attributes' do
      db[:users].insert name: 'User 1'

      users.exclude_attributes(:id).all.must_equal [User.new(name: 'User 1')]
    end

    it 'All attributes' do
      id = db[:users].insert name: 'User 1'

      users.select_attributes(:id).all_attributes.all.must_equal [User.new(id: id, name: 'User 1')]
    end

    it 'Count' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.count.must_equal 10
    end

    it 'All' do
      id = db[:users].insert name: 'User 1'

      users.all.must_equal [User.new(id: id, name: 'User 1')]
    end

    it 'Map' do
      1.upto(2) { |i| db[:users].insert name: "User #{i}" }

      users.map(&:name).sort.must_equal ['User 1', 'User 2']
    end

    it 'First' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.first.must_equal User.new(id: 1, name: 'User 1')
    end

    it 'Exists' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.exists?(id: 1).must_equal true
      users.exists?(id: 0).must_equal false

      users.exists? { where id: 1 }.must_equal true
      users.exists? { where id: 0 }.must_equal false
    end

    it 'Detect' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      users.detect(id: 1).must_equal User.new(id: 1, name: 'User 1')
      users.detect(id: 0).must_be_nil

      users.detect { where id: 1 }.must_equal User.new(id: 1, name: 'User 1')
      users.detect { where id: 0 }.must_be_nil
    end

    it 'Chained query' do
      1.upto(10) { |i| db[:users].insert name: "User #{i}" }

      models = users.where(id: [1,2]).reverse_order(:id).all

      models.must_equal [2,1].map { |i| User.new(id: i, name: "User #{i}") }
    end

    it 'Chain dataset as query' do
      1.upto(2) { |i| db[:users].insert name: "User #{i}" }
      1.upto(3) { |i| db[:posts].insert user_id: 1, title: "Post #{i}", body: '...', language_id: 1 }
      1.upto(2) { |i| db[:comments].insert post_id: i, user_id: 2, text: 'Comment' }

      models = posts.commented_by(2).all
      models.must_equal [1,2].map { |i| Post.new(id: i, user_id: 1, title: "Post #{i}", body: '...', language_id: 1) }
    end

    it 'Custom query' do
      1.upto(2) { |i| db[:users].insert name: "User #{i}" }
      1.upto(3) { |i| db[:posts].insert user_id: 1, title: "Post #{i}", body: '...', language_id: 1 }
      1.upto(2) { |i| db[:comments].insert post_id: i, user_id: 2, text: 'Comment' }

      models = comments.posts_commented_by(2)
      models.must_equal [1,2].map { |i| Post.new(id: i, user_id: 1, title: "Post #{i}", body: '...', language_id: 1) }
    end

    describe 'Named queries' do

      before do
        custom_db[:languages].insert name: 'Spanish'
        custom_db[:languages].insert name: 'English'

        1.upto(2) do |i|
          db[:categories].insert name: "Category #{i}"

          db[:users].insert name: "User #{i}"

          db[:people].insert document_number: "document_#{i}",
                             first_name: "John #{i}",
                             last_name: "Doe #{i}",
                             birth_date: Time.now - i,
                             user_id: i

        end

        db[:languages_people].insert language_id: 1, document_number: 'document_1'
        db[:languages_people].insert language_id: 2, document_number: 'document_2'

        1.upto(3) do |i|
          db[:posts].insert user_id: 1, title: "Post #{i}", body: '...', language_id: 1
          db[:categories_posts].insert category_id: 1, post_id: i
        end

        4.upto(5) do |i|
          db[:posts].insert user_id: 2, title: "Post #{i}", body: '...', language_id: 2
          db[:categories_posts].insert category_id: 2, post_id: i
        end
      end

      describe 'Relations' do

        it 'Many to Many' do
          posts.order(:id).with_categories(1).primary_keys.must_equal [1,2,3]
        end

        it 'One to Many' do
          users.with_posts([1,4]).primary_keys.must_equal [1,2]
        end

        it 'Many to One' do
          posts.with_users(2).primary_keys.must_equal [4,5]
        end

        it 'One to One' do
          users.with_people('document_1').primary_keys.must_equal [1]
        end

        describe 'Multiple data sources' do

          it 'One to many' do
            languages.with_posts([1,2]).primary_keys.must_equal [1]
          end

          it 'Many to one' do
            posts.with_languages([2]).primary_keys.must_equal [4,5]
          end

          it 'Many to Many' do
            languages.with_people(['document_1']).primary_keys.must_equal [1]
            people.with_languages([2]).primary_keys.must_equal ['document_2']
          end

        end

      end

      it 'Global' do
        result_1 = posts.created_by(1)
        result_1.primary_keys.must_equal [1,2,3]

        result_2 = posts.created_by(2)
        result_2.primary_keys.must_equal [4,5]
      end

      it 'Chained' do
        result = posts.created_by(2).entitled('Post 4')
        result.primary_keys.must_equal [4]
      end

    end

    it 'Graph' do
      1.upto(3) do |i|
        db[:users].insert name: "User #{i}"
        db[:people].insert document_number: "document_#{i}",
                           first_name: "John #{i}",
                           last_name: "Doe #{i}",
                           birth_date: Time.now - i,
                           user_id: i
        db[:categories].insert name: "Category #{i}"
        db[:posts].insert user_id: i, title: "Post #{i}", body: '...', language_id: 1
        db[:categories_posts].insert post_id: i, category_id: i
      end

      db[:posts].map(:id).each do |post_id|
        db[:users].map(:id).each do |user_id|
          db[:comments].insert post_id: post_id, user_id: user_id, text: 'Comment'
        end
      end

      posts_graph = posts.where(id: 1).graph('user.person', :categories, 'comments.user.posts.categories').all

      posts_graph.count.must_equal 1

      posts_graph[0].user.id.must_equal 1
      posts_graph[0].user.person.must_equal people.detect(user_id: 1)

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

        when 'SELECT users.* FROM schema_1.users',
             'SELECT users.* FROM schema_1.users WHERE (users.id IN (2, 1))'
          [
            {id: 1},
            {id: 2}
          ]

        when 'SELECT posts.* FROM schema_1.posts',
             'SELECT posts.* FROM schema_1.posts WHERE (posts.user_id IN (1, 2))'
          [
            {id: 3, user_id: 1, language_id: 1},
            {id: 4, user_id: 2, language_id: 2}
          ]

        when 'SELECT comments.* FROM schema_1.comments WHERE (comments.post_id IN (3, 4))'
          [
            {id: 5, user_id: 2, post_id: 3},
            {id: 6, user_id: 1, post_id: 3},
            {id: 7, user_id: 1, post_id: 4},
            {id: 8, user_id: 2, post_id: 4}
          ]

        when 'SELECT languages.* FROM schema_2.languages WHERE (languages.id IN (1, 2))'
          [
            {id: 1},
            {id: 2}
          ]

        end
      end

      last_id = 0
      autoid = Proc.new do |sql|
        case sql
        when "INSERT INTO schema_1.people (document_number, first_name, last_name, birth_date, user_id) VALUES ('document_1', 'John', 'Doe', '2020-04-24 00:00:00.000000', 1)"
          'document_1'
        else
          last_id += 1
        end
      end

      Sequel.mock fetch: stubs, autoid: autoid
    end

    let :stub_environment do
      Rasti::DB::Environment.new default: Rasti::DB::DataSource.new(stub_db, :schema_1),
                                 custom: Rasti::DB::DataSource.new(stub_db, :schema_2)
    end

    let(:stub_users)     { Users.new stub_environment }
    let(:stub_posts)     { Posts.new stub_environment }
    let(:stub_comments)  { Comments.new stub_environment }
    let(:stub_people)    { People.new stub_environment }
    let(:stub_languages) { Languages.new stub_environment }

    it 'Insert' do
      stub_users.insert name: 'User 1'

      stub_db.sqls.must_equal [
        'BEGIN',
        "INSERT INTO schema_1.users (name) VALUES ('User 1')",
        'COMMIT'
      ]
    end

    it 'Insert with many to many relation' do
      stub_posts.insert user_id: 1, title: 'Post 1', body: '...', categories: [2,3], language_id: 1

      stub_db.sqls.must_equal [
        'BEGIN',
        "INSERT INTO schema_1.posts (user_id, title, body, language_id) VALUES (1, 'Post 1', '...', 1)",
        'DELETE FROM schema_1.categories_posts WHERE (post_id IN (1))',
        'INSERT INTO schema_1.categories_posts (post_id, category_id) VALUES (1, 2)',
        'INSERT INTO schema_1.categories_posts (post_id, category_id) VALUES (1, 3)',
        'COMMIT'
      ]
    end

    it 'Insert in multiple schemas' do
      stub_languages.insert name: 'Spanish'

      stub_users.insert name: 'User 1'

      stub_people.insert document_number: 'document_1',
                         first_name: 'John',
                         last_name: 'Doe',
                         birth_date: Time.parse('2020-04-24'),
                         user_id: 1,
                         languages: [1]

      stub_db.sqls.must_equal [
        'BEGIN',
        "INSERT INTO schema_2.languages (name) VALUES ('Spanish')",
        'COMMIT',
        'BEGIN',
        "INSERT INTO schema_1.users (name) VALUES ('User 1')",
        'COMMIT',
        'BEGIN',
        "INSERT INTO schema_1.people (document_number, first_name, last_name, birth_date, user_id) VALUES ('document_1', 'John', 'Doe', '2020-04-24 00:00:00.000000', 1)",
        "DELETE FROM schema_1.languages_people WHERE (document_number IN ('document_1'))",
        "INSERT INTO schema_1.languages_people (document_number, language_id) VALUES ('document_1', 1)",
        'COMMIT'
      ]
    end

    it 'Update' do
      stub_users.update 1, name: 'Updated name'

      stub_db.sqls.must_equal [
        'BEGIN',
        "UPDATE schema_1.users SET name = 'Updated name' WHERE (id = 1)",
        'COMMIT'
      ]
    end

    it 'Delete' do
      stub_users.delete 1

      stub_db.sqls.must_equal [
        'DELETE FROM schema_1.users WHERE (id = 1)'
      ]
    end

    it 'Chained query' do
      stub_users.where(id: [1,2]).limit(1).order(:name).all

      stub_db.sqls.must_equal [
        'SELECT users.* FROM schema_1.users WHERE (users.id IN (1, 2)) ORDER BY users.name LIMIT 1'
      ]
    end

    it 'Graph' do
      stub_posts.graph(:user, :categories, 'comments.user.posts.categories', 'language.people').all

      stub_db.sqls.must_equal [
        'SELECT posts.* FROM schema_1.posts',
        'SELECT categories.*, categories_posts.post_id AS source_foreign_key FROM schema_1.categories INNER JOIN schema_1.categories_posts ON (schema_1.categories_posts.category_id = schema_1.categories.id) WHERE (categories_posts.post_id IN (3, 4))',
        'SELECT comments.* FROM schema_1.comments WHERE (comments.post_id IN (3, 4))',
        'SELECT users.* FROM schema_1.users WHERE (users.id IN (2, 1))',
        'SELECT posts.* FROM schema_1.posts WHERE (posts.user_id IN (1, 2))',
        'SELECT categories.*, categories_posts.post_id AS source_foreign_key FROM schema_1.categories INNER JOIN schema_1.categories_posts ON (schema_1.categories_posts.category_id = schema_1.categories.id) WHERE (categories_posts.post_id IN (3, 4))',
        'SELECT languages.* FROM schema_2.languages WHERE (languages.id IN (1, 2))',
        'SELECT people.*, languages_people.language_id AS source_foreign_key FROM schema_1.people INNER JOIN schema_1.languages_people ON (schema_1.languages_people.document_number = schema_1.people.document_number) WHERE (languages_people.language_id IN (1, 2))',
        'SELECT users.* FROM schema_1.users WHERE (users.id IN (1, 2))'
      ]
    end

    it 'Join' do
      stub_posts.join('user.person').where(document_number: 'document_1').all

      stub_db.sqls.must_equal [
        "SELECT DISTINCT posts.* FROM schema_1.posts INNER JOIN schema_1.users AS user ON (user.id = posts.user_id) INNER JOIN schema_1.people AS user__person ON (user__person.user_id = user.id) WHERE (posts.document_number = 'document_1')"
      ]
    end

    it 'Named query' do
      stub_posts.commented_by(1).all

      stub_db.sqls.must_equal [
        'SELECT DISTINCT posts.* FROM schema_1.posts INNER JOIN schema_1.comments ON (schema_1.comments.post_id = schema_1.posts.id) WHERE (comments.user_id = 1)'
      ]
    end

    it 'Custom query' do
      stub_comments.posts_commented_by(2)

      stub_db.sqls.must_equal [
        'SELECT posts.* FROM schema_1.comments INNER JOIN schema_1.posts ON (schema_1.posts.id = schema_1.comments.post_id) WHERE (comments.user_id = 2)'
      ]
    end

  end

end