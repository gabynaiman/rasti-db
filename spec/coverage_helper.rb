require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new [SimpleCov::Formatter::HTMLFormatter, Coveralls::SimpleCov::Formatter]

SimpleCov.start do
  add_filter 'lib/rasti/db/nql/syntax.rb'

  add_group 'Rasti::DB', 'lib'
  add_group 'Spec', 'spec'
end