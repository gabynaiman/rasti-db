require 'coverage_helper'
require 'rasti-db'
require 'minitest/autorun'
require 'minitest/colorin'
require 'minitest/line/describe_track'
require 'pry-nav'
require 'logger'
require 'sequel/extensions/pg_hstore'
require 'sequel/extensions/pg_array'
require 'sequel/extensions/pg_json'

Rasti::DB.configure do |config|
  config.type_converters = [Rasti::DB::TypeConverters::TimeInZone]
end

User     = Rasti::DB::Model[:id, :name, :posts, :comments, :person]
Post     = Rasti::DB::Model[:id, :title, :body, :user_id, :user, :comments, :categories]
Comment  = Rasti::DB::Model[:id, :text, :user_id, :user, :post_id, :post]
Category = Rasti::DB::Model[:id, :name, :posts]
Person   = Rasti::DB::Model[:document_number, :first_name, :last_name, :birth_date, :user_id, :user]


class Users < Rasti::DB::Collection
  one_to_many :posts
  one_to_many :comments
  one_to_one :person
end

class Posts < Rasti::DB::Collection
  many_to_one :user
  many_to_many :categories
  one_to_many :comments

  query :created_by, ->(user_id) { where user_id: user_id }
  
  query :entitled do |title| 
    where title: title
  end

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

  def posts_commented_by(user_id)
    dataset.where(Sequel[:comments][:user_id] => user_id)
           .join(with_schema(:posts), id: :post_id)
           .select_all(:posts)
           .map { |row| Post.new row }
  end
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


class Minitest::Spec

  let(:users) { Users.new db }

  let(:posts) { Posts.new db }
  
  let(:comments) { Comments.new db }

  let(:categories) { Categories.new db }

  let(:people) { People.new db }

  let :db do
    driver = (RUBY_ENGINE == 'jruby') ? 'jdbc:sqlite::memory:' : {adapter: :sqlite}

    Sequel.connect(driver).tap do |db|

      db.create_table :users do
        primary_key :id
        String :name, null: false, unique: true
      end

      db.create_table :posts do
        primary_key :id
        String :title, null: false, unique: true
        String :body, null: false
        foreign_key :user_id, :users, null: false, index: true
      end

      db.create_table :comments do
        primary_key :id
        String :text, null: false
        foreign_key :user_id, :users, null: false, index: true
        foreign_key :post_id, :posts, null: false, index: true
      end

      db.create_table :categories do
        primary_key :id
        String :name, null: false, unique: true
      end

      db.create_table :categories_posts do
        foreign_key :category_id, :categories, null: false, index: true
        foreign_key :post_id, :posts, null: false, index: true
        primary_key [:category_id, :post_id]
      end

      db.create_table :people do
        String :document_number, null: false, primary_key: true
        String :first_name, null: false
        String :last_name, null: false
        Date :birth_date, null: false
        foreign_key :user_id, :users, null: false, unique: true
      end

    end
  end

end