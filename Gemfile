source 'http://rubygems.org'

gem 'rails', '3.0.12'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

#gem 'radiustar', '~> 0.0.6'
#Temp radiustar repository for ipaddr version yanked
gem 'radiustar', :git =>'git://github.com/idemarinis/radiustar.git'
gem 'packet', '0.1.15', :git => 'git://github.com/dguerri/packet.git'
gem 'backgroundrb-rails3', :require => 'backgroundrb'

gem 'authlogic', '~> 2.1.6'
gem 'rails3-generators', '~> 0.17.4'

gem 'jquery-rails', '~> 0.2.6'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano', '~> 2.9.0', :require => false
gem 'capistrano-ext', '~> 1.2.1', :require => false
gem 'cap-recipes', '~> 0.3.36', :require => false
gem 'capistrano_colors', '~> 0.5.4', :require => false

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug19'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end

group :development, :test do
  gem 'wirble'
  gem 'hirb'
  gem 'awesome_print'
  gem 'ruby-debug'
  gem 'sqlite3-ruby', :require => 'sqlite3'
end

group :production do
  gem 'mysql'
end

# TODO: there is a bug in bundler that prevent us to use exception_notifier as a gem
# E.N. is now installed as a plugin
#group :production do
#  gem "exception_notification", :git => "git://github.com/rails/exception_notification.git", :branch => "master"
#end
