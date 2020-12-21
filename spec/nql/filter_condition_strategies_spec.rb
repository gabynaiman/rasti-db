require 'minitest_helper'

describe 'NQL::FilterConditionStrategies' do

  let(:comments_query) { Rasti::DB::Query.new collection_class: Comments, dataset: db[:comments], environment: environment }

  def sqls_where(query)
    "#<Rasti::DB::Query: \"SELECT `comments`.* FROM `comments` WHERE (#{query})\">"
  end

  def sqls_where_not(query)
    "#<Rasti::DB::Query: \"SELECT `comments`.* FROM `comments` WHERE NOT (#{query})\">"
  end

  def nql_s(nql_query)
    comments_query.nql(nql_query).to_s
  end

  describe 'Generic' do

    it 'Equal' do
      nql_s('text = hola').must_equal sqls_where("`comments`.`text` = 'hola'")
    end

    it 'Not Equal' do
      nql_s('text != hola').must_equal sqls_where("`comments`.`text` != 'hola'")
    end

    it 'Greather Than' do
      nql_s('id > 1').must_equal sqls_where("`comments`.`id` > 1")
    end

    it 'Greather Than or Equal' do
      nql_s('id >= 1').must_equal sqls_where("`comments`.`id` >= 1")
    end

    it 'Less Than' do
      nql_s('id < 1').must_equal sqls_where("`comments`.`id` < 1")
    end
    
    it 'Less Than or Equal' do
      nql_s('id <= 1').must_equal sqls_where("`comments`.`id` <= 1")
    end

    it 'Like' do
      nql_s('text ~ hola').must_equal sqls_where("UPPER(`comments`.`text`) LIKE UPPER('hola') ESCAPE '\\'")
    end

    it 'Include' do
      nql_s('text: hola').must_equal sqls_where("UPPER(`comments`.`text`) LIKE UPPER('%hola%') ESCAPE '\\'")
    end

    it 'Not Include' do
      nql_s('text!: hola').must_equal sqls_where_not("UPPER(`comments`.`text`) LIKE UPPER('%hola%') ESCAPE '\\'")
    end

  end

  describe 'SQLite Array' do

    it 'Equal' do
      nql_s('tags = [notice]').must_equal sqls_where("`comments`.`tags` = '[\"notice\"]'")
    end

    it 'Not Equal' do
      nql_s('tags != [notice]').must_equal sqls_where_not("`comments`.`tags` LIKE '%\"notice\"%' ESCAPE '\\'")
    end

    it 'Like' do
      nql_s('tags ~ [notice]').must_equal sqls_where("`comments`.`tags` LIKE '%notice%' ESCAPE '\\'")
    end

    it 'Include' do
      nql_s('tags: [notice]').must_equal sqls_where("`comments`.`tags` LIKE '%\"notice\"%' ESCAPE '\\'")
    end

    it 'Not Include' do
      nql_s('tags!: [notice]').must_equal sqls_where_not("`comments`.`tags` LIKE '%\"notice\"%' ESCAPE '\\'")
    end

  end

  describe 'Postgres Array' do

    before do
      Rasti::DB.nql_filter_condition_strategy = Rasti::DB::NQL::FilterConditionStrategies::Postgres.new
      Sequel.extension :pg_array_ops
    end

    after do
      Rasti::DB.nql_filter_condition_strategy = Rasti::DB::NQL::FilterConditionStrategies::SQLite.new
    end

    it 'Equal' do
      nql_s('tags = [notice]').must_equal sqls_where("(`comments`.`tags` @> ARRAY['notice']) AND (`comments`.`tags` <@ ARRAY['notice'])")
    end

    it 'Not Equal' do
      nql_s('tags != [notice]').must_equal sqls_where("NOT (`comments`.`tags` @> ARRAY['notice']) OR NOT (`comments`.`tags` <@ ARRAY['notice'])")
    end

    it 'Include' do
      nql_s('tags: [notice]').must_equal sqls_where("`comments`.`tags` && ARRAY['notice']")
    end

    it 'Not Include' do
      nql_s('tags!: [notice]').must_equal sqls_where_not("`comments`.`tags` && ARRAY['notice']")
    end

  end

end