require 'minitest_helper'

describe 'Model' do

  describe 'Attribues' do

    it 'Valid definition' do
      model = Rasti::DB::Model[:id, :name]
      model.attributes.must_equal [:id, :name]
    end

    it 'Invalid definition' do
      error = proc { Rasti::DB::Model[:id, :name, :name] }.must_raise ArgumentError
      error.message.must_equal 'Attribute name already exists'
    end

    it 'Accessors' do
      post = Post.new id: 1, title: 'Title'

      post.id.must_equal 1
      post.title.must_equal 'Title'

      [:body, :user, :comments].each do |attribute|
        error = proc { post.send attribute }.must_raise Rasti::DB::Model::UninitializedAttributeError
        error.message.must_equal "Uninitialized attribute #{attribute}"
      end

      proc { post.invalid_method }.must_raise NoMethodError
    end

  end


  it 'Inheritance' do
    subclass = Class.new(User) do
      attribute :additional_attribute
    end

    subclass.attributes.must_equal (User.attributes + [:additional_attribute])
  end

  describe 'To String' do
    
    it 'Class' do
      User.to_s.must_equal 'User[id, name, posts, comments, person]'
    end

    it 'Instance' do
      user = User.new id: 1, name: 'User 1'
      user.to_s.must_equal '#<User[id: 1, name: "User 1"]>'
    end

  end

  it 'To Hash' do
    post = Post.new id: 2, 
                    title: 'Title', 
                    body: 'body', 
                    user_id: 1, 
                    user: User.new(id: 1, name: 'User 1'), 
                    comments: [Comment.new(id: 4, text: 'comment text', user_id: 5)]

    post.to_h.must_equal id: 2,
                         title: 'Title', 
                         body: 'body', 
                         user_id: 1, 
                         user: {id: 1, name: 'User 1'}, 
                         comments: [{id: 4, text: 'comment text', user_id: 5}]
  end

  it 'Equality' do
    assert User.new(id: 1, name: 'User 1') == User.new(id: 1, name: 'User 1')
    refute User.new(id: 1, name: 'User 1') == User.new(id: 2, name: 'User 2')

    assert User.new(id: 1, name: 'User 1').eql? User.new(id: 1, name: 'User 1')
    refute User.new(id: 1, name: 'User 1').eql? User.new(id: 2, name: 'User 2')

    assert_equal User.new(id: 1, name: 'User 1').hash, User.new(id: 1, name: 'User 1').hash
    refute_equal User.new(id: 1, name: 'User 1').hash, User.new(id: 2, name: 'User 2').hash
  end

  it 'Merge' do
    user = User.new(id: 1, name: 'User 1')
    changed_user = user.merge(name: 'User 2')
    
    user.must_equal User.new(id: 1, name: 'User 1')
    changed_user.must_equal User.new(id: 1, name: 'User 2')
  end

end