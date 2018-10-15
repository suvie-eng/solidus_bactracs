source 'http://rubygems.org'

branch = ENV.fetch('SOLIDUS_BRANCH', 'master')
gem "solidus", github: "solidusio/solidus", branch: branch
gem 'guard', require: false
gem 'guard-rspec', require: false
gem 'pry-rails', require: false
gem 'codeclimate-test-reporter', group: :test, require: nil

gem 'pg', '~> 0.21'
gem 'mysql2', '~> 0.4.10'

group :development, :test do
  if branch == 'master' || branch >= "v2.0"
    gem "rails-controller-testing"
  else
    gem "rails_test_params_backport"
  end

  if branch < "v2.5"
    gem 'factory_bot', '4.10.0'
  else
    gem 'factory_bot', '> 4.10.0'
  end
end


gemspec
