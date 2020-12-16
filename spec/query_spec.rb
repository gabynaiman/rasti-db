require 'minitest_helper'

describe 'Query' do

  before do
    custom_db[:languages].insert name: 'Spanish'

    1.upto(10) do |i|
      db[:users].insert name: "User #{i}"

      db[:people].insert user_id: i,
                         document_number: "document_#{i}",
                         first_name: "Name #{i}",
                         last_name: "Last Name #{i}",
                         birth_date: Date.parse('2020-04-24')

      db[:languages_people].insert language_id: 1, document_number: "document_#{i}"
    end

    db[:posts].insert user_id: 2, title: 'Sample post', body: '...', language_id: 1
    db[:posts].insert user_id: 1, title: 'Another post', body: '...', language_id: 1
    db[:posts].insert user_id: 4, title: 'Best post', body: '...', language_id: 1

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

  let(:users_query) { Rasti::DB::Query.new collection_class: Users, dataset: db[:users], environment: environment }

  let(:posts_query) { Rasti::DB::Query.new collection_class: Posts, dataset: db[:posts], environment: environment }

  let(:comments_query) { Rasti::DB::Query.new collection_class: Comments, dataset: db[:comments], environment: environment }

  let(:people_query) { Rasti::DB::Query.new collection_class: People, dataset: db[:people], environment: environment }

  let(:languages_query) { Rasti::DB::Query.new collection_class: Languages, dataset: custom_db[:languages], environment: environment }

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

  it 'Select attributes' do
    posts_query.select_attributes(:id, :user_id).all.must_equal db[:posts].select(:id, :user_id).map { |r| Post.new r }
  end

  it 'Exclude attributes' do
    posts_query.exclude_attributes(:body).all.must_equal db[:posts].select(:id, :user_id, :title, :language_id).map { |r| Post.new r }
  end

  it 'All attributes' do
    posts_query.exclude_attributes(:body).all_attributes.all.must_equal db[:posts].map { |r| Post.new r }
  end

  it 'Select graph attributes' do
    language = Language.new custom_db[:languages].where(id: 1).select(:id).first

    person = Person.new db[:people].where(document_number: 'document_2').select(:document_number, :user_id).first.merge(languages: [language])

    user = User.new db[:users].where(id: 2).select(:id).first.merge(person: person)

    categories = db[:categories].where(id: [1,2]).select(:id).map { |c| Category.new c }

    post = Post.new db[:posts].where(id: 1).first.merge(user: user, categories: categories)

    selected_attributes = {
      user: [:id],
      'user.person' => [:document_number, :user_id],
      'user.person.languages' => [:id],
      categories: [:id]
    }

    posts_query.where(id: 1)
               .graph(*selected_attributes.keys)
               .select_graph_attributes(selected_attributes)
               .all
               .must_equal [post]
  end

  it 'Exclude graph attributes' do
    language = Language.new custom_db[:languages].where(id: 1).select(:id).first

    person = Person.new db[:people].where(document_number: 'document_2').select(:document_number, :user_id).first.merge(languages: [language])

    user = User.new db[:users].where(id: 2).select(:id).first.merge(person: person)

    categories = db[:categories].where(id: [1,2]).select(:id).map { |c| Category.new c }

    post = Post.new db[:posts].where(id: 1).first.merge(user: user, categories: categories)

    excluded_attributes = {
      user: [:name],
      'user.person' => [:first_name, :last_name, :birth_date],
      'user.person.languages' => [:name],
      categories: [:name]
    }

    posts_query.where(id: 1)
               .graph(*excluded_attributes.keys)
               .exclude_graph_attributes(excluded_attributes)
               .all
               .must_equal [post]
  end

  it 'All graph attributes' do
    person = Person.new db[:people].where(document_number: 'document_2').first

    user = User.new db[:users].where(id: 2).select(:id).first.merge(person: person)

    post = Post.new db[:posts].where(id: 1).first.merge(user: user)

    posts_query.where(id: 1)
               .graph('user.person')
               .exclude_graph_attributes(user: [:name], 'user.person' => [:birth_date, :first_name, :last_name])
               .all_graph_attributes('user.person')
               .all
               .must_equal [post]
  end

  describe 'Select computed attributes' do
    it 'With join' do
      db[:comments].insert post_id: 1, user_id: 5, text: 'Comment 4'
      users_query.select_computed_attributes(:comments_count)
                 .where(id: 5)
                 .all
                 .must_equal [User.new(id: 5, name: 'User 5', comments_count: 2)]
    end

    it 'Without join' do
      person_expected = Person.new user_id: 1,
                                   document_number: 'document_1',
                                   first_name: 'Name 1',
                                   last_name: 'Last Name 1',
                                   birth_date: Date.parse('2020-04-24'),
                                   full_name: 'Name 1 Last Name 1'

      people_query.select_computed_attributes(:full_name)
                  .where(document_number: 'document_1')
                  .all
                  .must_equal [person_expected]
    end
  end

  it 'Map' do
    users_query.map(&:name).must_equal db[:users].map(:name)
  end

  it 'Detect' do
    users_query.detect(id: 3).must_equal User.new(id: 3, name: 'User 3')
  end

  describe 'Each' do

    it 'without size' do
      users = []

      users_query.each do |user|
        users << user
      end

      users.size.must_equal 10
      users.each_with_index do |user, i|
        user.must_equal User.new(id: i+1, name: "User #{i+1}")
      end
    end

    it 'with size' do
      users = []
      users_query.each(batch_size: 2) do |user|
        users << user
      end

      users.size.must_equal 10
      users.each_with_index do |user, i|
        user.must_equal User.new(id: i+1, name: "User #{i+1}")
      end
    end

  end

  it 'Each batch' do
    users_batch = []
    users_query.each_batch(size: 2) do |page|
      users_batch << page
    end

    users_batch.size.must_equal 5
    i = 1
    users_batch.each do |user_page|
      user_page.must_equal [User.new(id: i, name: "User #{i}"), User.new(id: i+1, name: "User #{i+1}")]
      i += 2
    end
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
      Post.new(id: 2, user_id: 1, title: 'Another post', body: '...', language_id: 1),
      Post.new(id: 3, user_id: 4, title: 'Best post', body: '...', language_id: 1),
      Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...', language_id: 1)
    ]
  end

  it 'Reverse order' do
    posts_query.reverse_order(:title).all.must_equal [
      Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...', language_id: 1),
      Post.new(id: 3, user_id: 4, title: 'Best post', body: '...', language_id: 1),
      Post.new(id: 2, user_id: 1, title: 'Another post', body: '...', language_id: 1)
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
    users_query.graph(:posts).where(id: 1).first.must_equal User.new(id: 1, name: 'User 1', posts: [Post.new(id: 2, user_id: 1, title: 'Another post', body: '...', language_id: 1)])
  end

  it 'Graph with multiple data sources' do
    language = Language.new id: 1, name: 'Spanish'

    person = Person.new user_id: 2,
                        document_number: 'document_2',
                        first_name: 'Name 2',
                        last_name: 'Last Name 2',
                        birth_date: Date.parse('2020-04-24'),
                        languages: [language]

    user = User.new id: 2,
                    name: 'User 2',
                    person: person

    post = Post.new id: 1,
                    user_id: 2,
                    user: user,
                    title: 'Sample post',
                    body: '...',
                    language_id: 1,
                    language: language

    posts_query.where(id: 1).graph(:language, 'user.person.languages').first.must_equal post
  end

  it 'Any?' do
    users_query.empty?.must_equal false
    users_query.any?.must_equal true
  end

  it 'Empty?' do
    db[:comments].truncate

    comments_query.empty?.must_equal true
    comments_query.any?.must_equal false
  end

  it 'To String' do
    users_query.where(id: [1,2,3]).order(:name).to_s.must_equal '#<Rasti::DB::Query: "SELECT `users`.* FROM `users` WHERE (`users`.`id` IN (1, 2, 3)) ORDER BY `users`.`name`">'
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

    it 'One to Many' do
      users_query.join(:posts).where(Sequel[:posts][:title] => 'Sample post').all.must_equal [User.new(id: 2, name: 'User 2')]
    end

    it 'Many to One' do
      posts_query.join(:user).where(Sequel[:user][:name] => 'User 4').all.must_equal [Post.new(id: 3, user_id: 4, title: 'Best post', body: '...', language_id: 1)]
    end

    it 'One to One' do
      users_query.join(:person).where(Sequel[:person][:document_number] => 'document_1').all.must_equal [User.new(id: 1, name: 'User 1')]
    end

    it 'Many to Many' do
      posts_query.join(:categories).where(Sequel[:categories][:name] => 'Category 3').order(:id).all.must_equal [
        Post.new(id: 2, user_id: 1, title: 'Another post', body: '...', language_id: 1),
        Post.new(id: 3, user_id: 4, title: 'Best post', body: '...', language_id: 1),
      ]
    end

    it 'Nested' do
      posts_query.join('categories', 'comments.user.person')
                 .where(Sequel[:categories][:name] => 'Category 2')
                 .where(Sequel[:comments__user__person][:document_number] => 'document_7')
                 .all
                 .must_equal [Post.new(id: 1, user_id: 2, title: 'Sample post', body: '...', language_id: 1)]
    end

    it 'Excluded attributes permanents excluded when join' do
      posts_query.join(:user)
                 .exclude_attributes(:body)
                 .where(Sequel[:user][:name] => 'User 4')
                 .all
                 .must_equal [Post.new(id: 3, title: 'Best post', user_id: 4, language_id: 1)]

      posts_query.exclude_attributes(:body)
                 .join(:user)
                 .where(Sequel[:user][:name] => 'User 4')
                 .all
                 .must_equal [Post.new(id: 3, title: 'Best post', user_id: 4, language_id: 1)]
    end

    describe 'Multiple data sources' do

      it 'One to Many' do
        error = proc { languages_query.join(:posts).all }.must_raise RuntimeError
        error.message.must_equal 'Invalid join of multiple data sources: custom.languages > default.posts'
      end

      it 'Many to One' do
        error = proc { posts_query.join(:language).all }.must_raise RuntimeError
        error.message.must_equal 'Invalid join of multiple data sources: default.posts > custom.languages'
      end

      it 'Many to Many' do
        error = proc { languages_query.join(:people).all }.must_raise RuntimeError
        error.message.must_equal 'Invalid join of multiple data sources: custom.languages > default.people'
      end
    end

  end

  describe 'NQL' do

    it 'Invalid expression' do
      error = proc { posts_query.nql('a + b') }.must_raise Rasti::DB::NQL::InvalidExpressionError
      error.message.must_equal 'Invalid filter expression: a + b'
    end

    it 'Filter to self table' do
      posts_query.nql('user_id > 1')
                 .pluck(:user_id)
                 .sort
                 .must_equal [2, 4]
    end

    it 'Filter to join table' do
      posts_query.nql('categories.name = Category 2')
                 .pluck(:id)
                 .sort
                 .must_equal [1, 2]
    end

    it 'Filter to 2nd order relation' do
      posts_query.nql('comments.user.person.document_number = document_7')
                 .pluck(:id)
                 .must_equal [1]
    end

    it 'Filter combined' do
      posts_query.nql('(categories.id = 1 | categories.id = 3) & comments.user.person.document_number = document_2')
                 .pluck(:id)
                 .must_equal [2]
    end

    describe 'Computed Attributes' do

      it 'Filter relation computed attribute' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'Comment 4'
        users_query.nql('comments_count = 2').all.must_equal [User.new(id: 5, name: 'User 5')]
      end

      it 'Filter with relation computed attribute with "and" combined' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'Comment 4'
        db[:comments].insert post_id: 1, user_id: 4, text: 'Comment 3'
        users_query.nql('(comments_count > 1) & (id = 5)').all.must_equal [User.new(id: 5, name: 'User 5')]
      end

      it 'Filter relation computed attribute with "or" combined' do
        db[:comments].insert post_id: 1, user_id: 2, text: 'Comment 3'
        users_query.nql('(comments_count = 2) | (id = 5)')
                  .order(:id)
                  .all
                  .must_equal [ User.new(id: 2, name: 'User 2'), User.new(id: 5, name: 'User 5') ]
      end

      it 'Filter relation computed attribute with "and" and "or" combined' do
        db[:comments].insert post_id: 1, user_id: 2, text: 'Comment 3'
        users_query.nql('((comments_count = 2) | (id = 5)) & (name: User 5)')
                  .order(:id)
                  .all
                  .must_equal [ User.new(id: 5, name: 'User 5') ]
      end

      it 'Filter simple computed attribute' do
        person_expected = Person.new user_id: 1,
                                     document_number: 'document_1',
                                     first_name: 'Name 1',
                                     last_name: 'Last Name 1',
                                     birth_date: Date.parse('2020-04-24')

        people_query.nql('full_name = Name 1 Last Name 1')
                    .all
                    .must_equal [person_expected]
      end

    end

    describe 'Filter Array' do

      def filter_condition_must_raise(comparison_symbol, comparison_name)
        error = proc { comments_query.nql("tags #{comparison_symbol} (fake, notice)") }.must_raise Rasti::DB::NQL::FilterConditionStrategies::UnsupportedTypeComparison
        error.argument_type.must_equal Rasti::DB::NQL::FilterConditionStrategies::Types::SQLiteArray
        error.comparison_name.must_equal comparison_name
        error.message.must_equal "Unsupported comparison #{comparison_name} for Rasti::DB::NQL::FilterConditionStrategies::Types::SQLiteArray"
      end

      it 'Must raise exception from not supported methods' do
        comparisons = {
          greater_than: '>',
          greater_than_or_equal: '>=',
          less_than: '<',
          less_than_or_equal: '<='
        }

        comparisons.each do |name, symbol|
          filter_condition_must_raise symbol, name
        end
      end

      it 'Included any of these elements' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake","notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice 2', tags: '["notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice 3', tags: '["fake_notice"]'
        expected_comments = [
          Comment.new(id: 4, text: 'fake notice', tags: '["fake","notice"]', user_id: 5, post_id: 1),
          Comment.new(id: 5, text: 'fake notice 2', tags: '["notice"]', user_id: 5, post_id: 1)
        ]
        comments_query.nql('tags: (fake, notice)')
                    .all
                    .must_equal expected_comments
      end

      it 'Included exactly all these elements' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake","notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice 2', tags: '["notice"]'
        comments_query.nql('tags = (fake, notice)')
                    .all
                    .must_equal [Comment.new(id: 4, text: 'fake notice', tags: '["fake","notice"]', user_id: 5, post_id: 1)]
      end

      it 'Not included anyone of these elements' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake","notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'Good notice!', tags: '["good"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake"]'
        expected_comments = [
          Comment.new(id: 1, text: 'Comment 1', tags: '[]', user_id: 5, post_id: 1),
          Comment.new(id: 2, text: 'Comment 2', tags: '[]', user_id: 7, post_id: 1),
          Comment.new(id: 3, text: 'Comment 3', tags: '[]', user_id: 2, post_id: 2),
          Comment.new(id: 5, text: 'Good notice!', tags: '["good"]', user_id: 5, post_id: 1)
        ]
        comments_query.nql('tags !: (fake, notice)')
                    .all
                    .must_equal expected_comments
      end

      it 'Not include any of these elements' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake","notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'Good notice!', tags: '["good"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake"]'
        expected_comments = [
          Comment.new(id: 1, text: 'Comment 1', tags: '[]', user_id: 5, post_id: 1),
          Comment.new(id: 2, text: 'Comment 2', tags: '[]', user_id: 7, post_id: 1),
          Comment.new(id: 3, text: 'Comment 3', tags: '[]', user_id: 2, post_id: 2),
          Comment.new(id: 5, text: 'Good notice!', tags: '["good"]', user_id: 5, post_id: 1),
          Comment.new(id: 6, text: 'fake notice', tags: '["fake"]', user_id: 5, post_id: 1)
        ]
        comments_query.nql('tags != (fake, notice)')
                    .all
                    .must_equal expected_comments
      end

      it 'Include any like these elements' do
        db[:comments].insert post_id: 1, user_id: 5, text: 'fake notice', tags: '["fake","notice"]'
        db[:comments].insert post_id: 1, user_id: 5, text: 'this is a fake notice!', tags: '["fake_notice"]'
        expected_comments = [
          Comment.new(id: 4, text: 'fake notice', tags: '["fake","notice"]', user_id: 5, post_id: 1),
          Comment.new(id: 5, text: 'this is a fake notice!', tags: '["fake_notice"]', user_id: 5, post_id: 1)
        ]
        comments_query.nql('tags ~ (fake)')
                      .all
                      .must_equal expected_comments
      end

    end

  end

end