require 'minitest_helper'

describe 'ComputedAttributes' do

  it 'Apply to Relation Computed Attribute must generate correct query' do
    dataset = db[:comments]
    computed_attribute = Rasti::DB::ComputedAttributes::Relation.new value: Sequel.function('count', :id),
                                                                     table: dataset,
                                                                     type: :inner,
                                                                     foreign_key: :user_id,
                                                                     primary_key: :id,
                                                                     attributes: [:field1, :field2]

    expected_query = "SELECT * FROM `comments` INNER JOIN (SELECT count(`id`) AS 'value', `field1`, `field2`, `user_id` FROM `comments` GROUP BY `user_id`) AS 'count_comments' ON (`count_comments`.`user_id` = `comments`.`id`)"
    computed_attribute.apply_to(dataset, :count_comments)
                      .sql
                      .must_equal expected_query
  end

  it 'Apply to Simple Computed Attribute must generate correct query' do
    primary_key = People.primary_key
    dataset = db[:people]
    computed_attribute = Rasti::DB::ComputedAttributes::Simple.new value: Sequel.join([:first_name, ' ', :last_name]),
                                                                   table: dataset,
                                                                   primary_key: primary_key

    expected_query = "SELECT * FROM `people` INNER JOIN (SELECT (`first_name` || ' ' || `last_name`) AS 'value', `#{primary_key}` FROM `people`) AS 'full_text' ON (`full_text`.`#{primary_key}` = `people`.`#{primary_key}`)"
    computed_attribute.apply_to(dataset, :full_text)
                      .sql
                      .must_equal expected_query
  end

end