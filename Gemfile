source 'http://rubygems.org'

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem 'guard', require: false
gem 'guard-rspec', require: false
gem 'pry-rails', require: false
gem 'codeclimate-test-reporter', group: :test, require: nil

gem 'pg'
gem 'mysql2'

if branch == 'master' || branch >= 'v2.0'
  gem "rails-controller-testing", group: :test
else
  gem "rails", '~> 4.2.7' # workaround for bundler resolution issue
  gem "rails_test_params_backport", group: :test
end

gemspec
