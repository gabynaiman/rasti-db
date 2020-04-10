# Rasti::DB

[![Gem Version](https://badge.fury.io/rb/rasti-db.svg)](https://rubygems.org/gems/rasti-db)
[![Build Status](https://travis-ci.org/gabynaiman/rasti-db.svg?branch=master)](https://travis-ci.org/gabynaiman/rasti-db)
[![Coverage Status](https://coveralls.io/repos/github/gabynaiman/rasti-db/badge.svg?branch=master)](https://coveralls.io/github/gabynaiman/rasti-db?branch=master)
[![Code Climate](https://codeclimate.com/github/gabynaiman/rasti-db.svg)](https://codeclimate.com/github/gabynaiman/rasti-db)

Database collections and relations

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rasti-db'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rasti-db

## Usage

### Database connection

```ruby
DB = Sequel.connect ...
```

### Database schema

```ruby
DB.create_table :users do
  primary_key :id
  String :name, null: false, unique: true
end

DB.create_table :posts do
  primary_key :id
  String :title, null: false, unique: true
  String :body, null: false
  foreign_key :user_id, :users, null: false, index: true
end

DB.create_table :comments do
  primary_key :id
  String :text, null: false
  foreign_key :user_id, :users, null: false, index: true
  foreign_key :post_id, :posts, null: false, index: true
end

DB.create_table :categories do
  primary_key :id
  String :name, null: false, unique: true
end

DB.create_table :categories_posts do
  foreign_key :category_id, :categories, null: false, index: true
  foreign_key :post_id, :posts, null: false, index: true
  primary_key [:category_id, :post_id]
end

DB.create_table :people do
  String :document_number, null: false, primary_key: true
  String :first_name, null: false
  String :last_name, null: false
  Date :birth_date, null: false
  foreign_key :user_id, :users, null: false, unique: true
end
```

### Models

```ruby
User     = Rasti::DB::Model[:id, :name, :posts, :comments, :person]
Post     = Rasti::DB::Model[:id, :title, :body, :user_id, :user, :comments, :categories]
Comment  = Rasti::DB::Model[:id, :text, :user_id, :user, :post_id, :post]
Category = Rasti::DB::Model[:id, :name, :posts]
Person   = Rasti::DB::Model[:document_number, :first_name, :last_name, :birth_date, :user_id, :user]
```

### Collections

```ruby
class Users < Rasti::DB::Collection
  one_to_many :posts
  one_to_many :comments
  one_to_one :person
end

class Posts < Rasti::DB::Collection
  many_to_one :user
  many_to_many :categories
  one_to_many :comments

  query :created_by do |user_id| 
    where user_id: user_id
  end
  
  query :entitled, -> (title) { where title: title }

  query :commented_by do |user_id|
    chainable do
      dataset.join(with_schema(:comments), post_id: :id)
             .where(with_schema(:comments, :user_id) => user_id)
             .select_all(:posts)
             .distinct
    end
  end
end

class Comments < Rasti::DB::Collection
  many_to_one :user
  many_to_one :post
end

class Categories < Rasti::DB::Collection
  many_to_many :posts
end

class People < Rasti::DB::Collection
  set_collection_name :people
  set_primary_key :document_number
  set_foreign_key :document_number
  set_model Person

  many_to_one :user
end

users      = Users.new DB
posts      = Posts.new DB
comments   = Comments.new DB
categories = Categories.new DB
people     = People.new DB
```

### Persistence

```ruby
DB.transaction do
  id = users.insert name: 'User 1'
  users.update id, name: 'User updated'
  users.delete id

  users.bulk_insert [{name: 'User 1'}, {name: 'User 2'}]
  users.bulk_update(name: 'User updated') { where id: [1,2] }
  users.bulk_delete { where id: [1,2] }

  posts.insert_relations 1, categories: [2,3]
  posts.delete_relations 1, categories: [2,3]
end
```

### Queries

```ruby
posts.all # => [Post, ...]
posts.first # => Post
posts.count # => 1
posts.where(id: [1,2]) # => [Post, ...]
posts.where{id > 1}.limit(10).offset(20) } # => [Post, ...]
posts.graph(:user, :categories, 'comments.user') # => [Post(User, [Categories, ...], [Comments(User)]), ...]
posts.created_by(1) # => [Post, ...]
posts.created_by(1).entitled('...').commented_by(2) # => [Post, ...]
posts.with_categories([1,2]) # => [Post, ...]
posts.where(id: [1,2]).raw # => [{id:1, ...}, {id:2, ...}]
posts.where(id: [1,2]).primary_keys # => [1,2]
posts.where(id: [1,2]).pluck(:id) # => [1,2]
posts.where(id: [1,2]).pluck(:id, :title) # => [[1, ...], [2, ...]]
posts.select_attributes(:id, :title) # => [Post, ...]
posts.exclude_attributes(:id, :title) # => [Post, ...]
posts.all_attributes # => [Post, ...]
posts.join(:user).where(name: 'User 4') # => [Post, ...]
```
### Natural Query Language

```ruby
posts.nql('id = 1') # => Equal
posts.nql('id != 1') # => Not equal
posts.nql('title: My post') # => Include
posts.nql('title !: My post') # => Not include
posts.nql('title ~ My post') # => Insensitive like
posts.nql('id > 1') # => Greater
posts.nql('id >= 1') # => Greater or equal
posts.nql('id < 10') # => Less
posts.nql('id <= 10') # => Less or equal

posts.nql('id = 1 | id = 2') # => Or
posts.nql('id > 1 & title: "My post"') # => And
posts.nql('(id > 3 & id < 10) | title: "My post"') # => Precedence

posts.nql('comments.user.person.document_number = 7') # => Nested
```

## Development

Rasti::DB uses treetop to perform queries using natural language. To recompile the syntax, simply run the following command in `lib/rasti/db/nql`:

```
tt syntax.treetop -o syntax.rb
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/gabynaiman/rasti-db.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

