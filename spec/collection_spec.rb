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

    it 'Insert' do
      id = users.insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'
    end

    it 'Update' do
      id = db[:users].insert name: 'User 1'

      db[:users][id: id][:name].must_equal 'User 1'

      users.update id, name: 'updated'

      db[:users][id: id][:name].must_equal 'updated'
    end

    it 'Delete' do
      id = db[:users].insert name: 'User 1'

      db[:users].count.must_equal 1

      users.delete id

      db[:users].count.must_equal 0
    end

    it 'Fetch' do
      id = db[:users].insert name: 'User 1'
      
      users.fetch(id).must_equal User.new(id: id, name: 'User 1')
    end

    it 'Count' do
      10.times do |i|
        db[:users].insert name: "User #{i}"
      end

      users.count.must_equal 10
    end

    it 'All' do
      id = db[:users].insert name: 'User 1'

      users.all.must_equal [User.new(id: id, name: 'User 1')]
    end

  end

end