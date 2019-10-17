run 'pgrep spring | xargs kill -9'

# GEMFILE
run 'rm Gemfile'
file 'Gemfile', <<-RUBY
source 'https://rubygems.org'
ruby '#{RUBY_VERSION}'
#{"gem 'bootsnap', require: false" if Rails.version >= "5.2"}
gem 'jbuilder', '~> 2.0'
gem 'pg', '~> 0.21'
gem 'puma'
gem 'rails', '#{Rails.version}'
gem 'redis'
gem 'autoprefixer-rails'
gem 'font-awesome-sass', '~> 5.6.1'
gem 'sassc-rails'
gem 'simple_form'
gem 'uglifier'
gem 'webpacker'

gem 'devise'

gem 'remotipart', github: 'mshibuya/remotipart'
gem 'rails_admin', '>= 1.0.0.rc'

group :development do
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'listen', '~> 3.0.5'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'dotenv-rails'
end
RUBY

# Ruby versio
file '.ruby-version', RUBY_VERSION

# Procfil
# file 'Procfile', <<-YAML
# web: bundle exec puma -C config/puma.rb
# YAML

# Clevercloud conf fil
# file 'clevercloud/ruby.json', <<-EOF
# {
#   "deploy": {
#     "rakegoals": ["assets:precompile", "db:migrate"]
#   }
# }
# EOF

# Database conf fil
inside 'config' do
  database_conf = <<-EOF
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
development:
  <<: *default
  database: #{app_name}_development
test:
  <<: *default
  database: #{app_name}_test
production:
  <<: *default
  url: <%= ENV['POSTGRESQL_ADDON_URI'] %>
  EOF
  file 'database.yml', database_conf, force: true
end

# Assets
run 'rm -rf app/assets/stylesheets'
# run 'rm -rf vendor'
run 'curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'
run 'rm app/assets/stylesheets/components/_avatar.scss'
run 'rm app/assets/stylesheets/components/_navbar.scss'
run 'rm app/assets/stylesheets/components/_index.scss'
file 'app/assets/stylesheets/components/_index.scss', <<-SCSS
// Import your components CSS files here.
@import "alert";
SCSS

run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
//= require rails-ujs
//= require_tree .
JS

# Dev environmen
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layou
run 'rm app/views/layouts/application.html.erb'
file 'app/views/layouts/application.html.erb', <<-HTML
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <title>TODO</title>
    <%= csrf_meta_tags %>
    <%= action_cable_meta_tag %>
    <%= stylesheet_link_tag 'application', media: 'all' %>
    <%#= stylesheet_pack_tag 'application', media: 'all' %> <!-- Uncomment if you import CSS in app/javascript/packs/application.js -->
  </head>
  <body>
    <%= render 'shared/flashes' %>
    <%= yield %>
    <%= javascript_include_tag 'application' %>
    <%= javascript_pack_tag 'application' %>
  </body>
</html>
HTML

file 'app/views/shared/_flashes.html.erb', <<-HTML
<% if notice %>
  <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
    <%= notice %>
    <button type="button" class="close" data-dismiss="alert" aria-label="Close">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>
<% end %>
<% if alert %>
  <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
    <%= alert %>
    <button type="button" class="close" data-dismiss="alert" aria-label="Close">
      <span aria-hidden="true">&times;</span>
    </button>
  </div>
<% end %>
HTML

# READM
markdown_file_content = <<-MARKDOWN
Rails app generated based on the awesome [lewagon/rails-templates](https://github.com/lewagon/rails-templates) ([Le Wagon coding bootcamp](https://www.lewagon.com)).
MARKDOWN
file 'README.md', markdown_file_content, force: true

# Generator
# generators = <<-RUBY
# config.generators do |generate|
#       generate.assets false
#       generate.helper false
#       generate.test_framework :test_unit, fixture: false
#     end
# RUBY

# environment generators
# AFTER BUNDL
after_bundle do
  # Generators: db + simple form + pages controller
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', 'about', 'contact', '--skip-routes', '--no-test-framework')

  # Routes
  route "root to: 'pages#home'"
  route "get 'pages/about'"
  route "get 'pages/contact'"

  # Git ignore
  append_file '.gitignore', <<-TXT
# Ignore .env file containing credentials.
.env*
# Ignore Mac and Linux file system files
*.swp
.DS_Store
  TXT

  # Devise install + user
  generate('devise:install')
  generate('devise', 'User')

  # App controller
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :authenticate_user!
end
  RUBY

  # migrate + devise views
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]
  def home
  end
end
  RUBY

  # RAILS ADMIN
  generate('migration AddAdminToUsers')

  append_file '/.*_add_admin_to_users.rb/', <<-RUBY
class AddAdminToUsers < ActiveRecord::Migration[#{Rails.version.first(3)}]
  def change
    add_column :users, :admin, :boolean, null: false, default: false
  end
end
  RUBY
  rails_command 'db:migrate'

  generate('rails_admin:install')
  # RAILS ADMIN


  # Environments
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  run 'rm app/javascript/packs/application.js'
  run 'yarn add popper.js jquery bootstrap'
  file 'app/javascript/packs/application.js', <<-JS
import "bootstrap";
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do <<-JS
const webpack = require('webpack')
// Preventing Babel from transpiling NodeModules packages
environment.loaders.delete('nodeModules');
// Bootstrap 4 has a dependency over jQuery & Popper.js:
environment.plugins.prepend('Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    Popper: ['popper.js', 'default']
  })
);
  JS
  end

  # Dotenv
  run 'touch .env'


end

# Rubocop
run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

# Git
git :init
git add: '.'
git commit: "-m 'Initial commit with devise & rails admin template'"
