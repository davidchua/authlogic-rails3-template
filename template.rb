# Application Generator Template

# If you are customizing this template, you can use any methods provided by Thor::Actions
# https://rdoc.info/rdoc/wycats/thor/blob/f939a3e8a854616784cac1dcff04ef4f3ee5f7ff/Thor/Actions.html
# and Rails::Generators::Actions
# https://github.com/rails/rails/blob/master/railties/lib/rails/generators/actions.rb

puts "Creating a new Rails app to use Rails 3 - email as form of user login "

#----------------------------------------------------------------------------
# Configure
#----------------------------------------------------------------------------

#if yes?('Are you using Rails 3.x? (yes/no)')
#  rails3_flag = true
#else
#  rails3_flag = false
#end

#login_method = ask('How do you prefer your users to login? (email/username/both) - defaults to email only')
#if login_method == "email"
#  login_method_flag = "email"
#elsif login_method == "username"
#  login_method_flag = "login"
#elsif login_method == "both"
#  login_method_flag = "both"
#else
#  login_method_flag = "email"
#end

#git_flag = true

#if no?('Would you like to setup an empty git repository? (yes/no)')
#  git_flag = false
#end
#----------------------------------------------------------------------------
# Remove the usual cruft
#----------------------------------------------------------------------------
puts "removing unneeded files..."

run 'rm public/index.html'
run 'rm public/favicon.ico'
run 'rm public/images/rails.png'
run 'rm README'
run 'touch README'

puts "banning spiders from your site by changing robots.txt..."
gsub_file 'public/robots.txt', /# User-Agent/, 'User-Agent'
gsub_file 'public/robots.txt', /# Disallow/, 'Disallow'

#----------------------------------------------------------------------------
# Setup Authlogic!
#----------------------------------------------------------------------------

gem "authlogic"
plugin "dynamic_form", :git => "git://github.com/rails/dynamic_form.git"


# setup user_session model

create_file "app/models/user_session.rb" do
<<-RUBY
  class UserSession < Authlogic::Session::Base
  end
RUBY
end

# setup user model

generate :model, 'user'

# add user model
inject_into_file Dir["db/migrate/*_create_users.rb"].first, :after => "do |t|" do
  <<-RUBY
      t.string    :email,               :null => false
      t.string    :crypted_password,    :null => false
      t.string    :password_salt,       :null => false
      t.string    :persistence_token,   :null => false
      t.string    :single_access_token, :null => false
      t.string    :perishable_token,    :null => false

      t.integer   :login_count,         :null => false, :default => 0
      t.integer   :failed_login_count,  :null => false, :default => 0
      t.datetime  :last_request_at
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.string    :current_login_ip
      t.string    :last_login_ip

  RUBY
end

# setup authlogic into user model

inject_into_file 'app/models/user.rb', :after => "class User < ActiveRecord::Base" do
  <<-RUBY

    acts_as_authentic do |c|
    end
  RUBY
end

# copy application controller
run "cd app/controllers && rm application_controller.rb"
run "cd app/controllers && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/controllers/application_controller.rb --no-check-certificate"

# generate user_sessions controllers and views

run "cd app/controllers && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/controllers/user_sessions_controller.rb --no-check-certificate"
run 'mkdir app/views/users'
run "cd app/views/users && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/views/users/edit.html.erb --no-check-certificate"
run "cd app/views/users && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/views/users/_form.erb --no-check-certificate"
run "cd app/views/users && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/views/users/new.html.erb --no-check-certificate"
run "cd app/views/users && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/views/users/show.html.erb --no-check-certificate"

# generate users controllers and views

run "cd app/controllers && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/controllers/users_controller.rb --no-check-certificate"
run 'mkdir app/views/user_sessions'
run "cd app/views/user_sessions && wget https://github.com/davidchua/authlogic3-rails-template/raw/master/views/user_sessions/new.html.erb --no-check-certificate"

# add routes


inject_into_file 'config/routes.rb', :after => "Application.routes.draw do" do
  <<-RUBY

    resources :user_session
    resources :users
    resource :account, :controller => "users"
  RUBY
end

# cleanups
run 'cp config/database.yml config/database.yml.example'


#----------------------------------------------------------------------------
# Set up git
#----------------------------------------------------------------------------

#if git_flag
puts "setting up source control with 'git'..."
# specific to Mac OS X
append_file '.gitignore' do
  '.DS_Store'
  'log/*'
  'config/database.yml'
end
git :init
git :add => '.'
git :commit => "-m 'Initial commit of unmodified new Rails app with authlogic'"
# end
