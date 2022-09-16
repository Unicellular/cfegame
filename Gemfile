source 'https://rubygems.org'
ruby "2.7.6"

gem 'rails', '~> 6.0.0'

group :development, :test do
  gem 'sqlite3', '>= 1.3.0'
  gem 'rspec-rails'
  gem 'pry-rails'
  gem 'byebug'
  gem 'listen', '~> 3.0'
end

group :development do
  gem 'web-console'
end

group :production do
  gem 'pg', '>= 0.18'
  gem 'rails_12factor'
end

gem 'sassc-rails', '~> 2.1'
gem 'bootstrap-sass', '~> 3.4'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'jquery-turbolinks'
gem 'turbolinks'
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

install_if -> { RUBY_PLATFORM =~ /x86_64-linux-?(?!.*musl).*/ } do
  gem 'mini_racer'
end

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end
