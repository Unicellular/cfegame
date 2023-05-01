source 'https://rubygems.org'
ruby "3.2.0"

gem 'rails', '~> 7.0.0'

group :development, :test do
  gem 'sqlite3', '>= 1.3.0'
  gem 'rspec-rails'
  gem 'pry-rails'
  gem 'debug', '>= 1.0.0', require: false
  gem 'ruby-debug-ide'
  gem 'debase', '0.2.2'
  gem 'listen', '~> 3.0'
end

group :development do
  gem 'web-console'
end

group :production do
  gem 'pg', '>= 0.18'
  gem 'rails_12factor'
end

gem 'sprockets-rails'
gem 'importmap-rails'
gem 'sassc-rails', '~> 2.1'
gem 'bootstrap', '~> 5.2'
gem 'terser'
gem 'mini_racer'
gem 'turbo-rails'
gem 'jbuilder', '~> 2.6'
gem 'slim-rails'
#gem 'react-rails'
gem 'thin'
gem 'bootsnap', require: false

# for log in
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'omniauth-facebook'
gem 'omniauth-rails_csrf_protection'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end
