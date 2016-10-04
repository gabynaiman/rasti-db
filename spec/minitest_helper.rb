require 'coverage_helper'
require 'rasti-db'
require 'minitest/autorun'
require 'minitest/colorin'
require 'pry-nav'
require 'logger'

User     = Rasti::DB::Model[:id, :name, :posts, :comments]
Post     = Rasti::DB::Model[:id, :title, :body, :user_id, :user, :comments, :categories]
Comment  = Rasti::DB::Model[:id, :text, :user_id, :user, :post_id, :post]
Category = Rasti::DB::Model[:id, :name, :posts]


class Users < Rasti::DB::Collection
  one_to_many :posts
  one_to_many :comments
end

class Posts < Rasti::DB::Collection
  many_to_one :user
  many_to_many :categories
  one_to_many :comments

  query :created_by do |user_id| 
    where user_id: user_id
  end
  
  query :entitled, -> (title) { where title: title }
end

class Comments < Rasti::DB::Collection
  many_to_one :user
  many_to_one :post
end

class Categories < Rasti::DB::Collection
  many_to_many :posts
end


class Minitest::Spec

  DB_DRIVER = (RUBY_ENGINE == 'jruby') ? 'jdbc:sqlite::memory:' : {adapter: :sqlite}

  let(:users) { Users.new db }

  let(:posts) { Posts.new db }
  
  let(:comments) { Comments.new db }

  let(:categories) { Categories.new db }

  let :db do
    db = Sequel.connect DB_DRIVER

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

    db
  end

end