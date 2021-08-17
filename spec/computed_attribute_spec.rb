require 'minitest_helper'

describe 'ComputedAttribute' do

  it 'Apply Join with join attribute must generate correct query' do
    dataset = db[:users]
    computed_attribute = Rasti::DB::ComputedAttribute.new(Sequel[:comments_count][:value]) do |dataset|
      subquery = dataset.db.from(:comments)
                           .select(Sequel[:user_id], Sequel.function('count', :id).as(:value))
                           .group(:user_id)
                           .as(:comments_count)

      dataset.join_table(:inner, subquery, :user_id => :id)
    end
    expected_query = "SELECT *, `comments_count`.`value` AS 'value' FROM `users` INNER JOIN (SELECT `user_id`, count(`id`) AS 'value' FROM `comments` GROUP BY `user_id`) AS 'comments_count' ON (`comments_count`.`user_id` = `users`.`id`)"
    computed_attribute.apply_join(dataset, environment)
                      .select_append(computed_attribute.identifier)
                      .sql
                      .must_equal expected_query
  end

  it 'Apply join without join attribute must generate correct query' do
    dataset = db[:people]
    computed_attribute = Rasti::DB::ComputedAttribute.new Sequel.join([:first_name, ' ', :last_name])
    expected_query = "SELECT * FROM `people` WHERE ((`first_name` || ' ' || `last_name`) = 'FULL NAME')"
    computed_attribute.apply_join(dataset, environment)
                      .where(computed_attribute.identifier => 'FULL NAME')
                      .sql
                      .must_equal expected_query
  end

  it 'Apply join with join and environment attributes must generate correct query' do
    dataset = db[:users]

    expected_query = "SELECT *, `comments_count`.`value` AS 'value' FROM `users` INNER JOIN (SELECT `user_id`, count(`id`) AS 'value' FROM `comments` GROUP BY `user_id`) AS 'comments_count' ON (`comments_count`.`user_id` = `users`.`id`)"

    computed_attribute = Rasti::DB::ComputedAttribute.new(Sequel[:comments_count][:value]) do |dataset, environment|
      subquery = dataset.db.from(environment.data_source(:custom).qualify(:comments))
                           .select(Sequel[:user_id], Sequel.function('count', :id).as(:value))
                           .group(:user_id)
                           .as(:comments_count)

      dataset.join_table(:inner, subquery, :user_id => :id)
    end

    computed_attribute.apply_join(dataset, environment)
                      .select_append(computed_attribute.identifier)
                      .sql
                      .must_equal expected_query
  end

end