# ask an expert
run 'pgrep spring | xargs kill -9'

# GEMFILE
run 'rm Gemfile' # seems to only remove the content of the file
file 'Gemfile', <<-RUBY
  source 'https://rubygems.org'
  ruby '#{RUBY_VERSION}'

  # #{"gem 'bootsnap', require: false" if Rails.version >= "5.2"} => not necessary since rails > 5.2
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

# RUBY VERSION
file '.ruby-version', RUBY_VERSION

# ask an expert
# PROCFILE
file 'Procfile', <<-YAML
  web: bundle exec puma -C config/puma.rb
YAML

# ask an expert
# CLEVERCLOUD
# removed, didn't seem useful

# ask an expert
# DATABASE TO PGSQL
inside 'config' do
  database_config = <<-EOF
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
  file 'database.yml', database_config, force: true
end

# ASSETS
run 'rm -rf app/assets/stylesheets'
# run 'rm -rf vendor' => let's keep it?
# following lines are temporary:
run 'curl -L https://github.com/lewagon/stylesheets/archive/master.zip > stylesheets.zip'
run 'unzip stylesheets.zip -d app/assets && rm stylesheets.zip && mv app/assets/rails-stylesheets-master app/assets/stylesheets'
run 'rm app/assets/stylesheets/components/_avatar.scss'
run 'rm app/assets/stylesheets/components/_navbar.scss'

# JAVASCRIPT
run 'rm app/assets/javascripts/application.js'
file 'app/assets/javascripts/application.js', <<-JS
  //= require rails-ujs
  //= require_tree .
JS

# ENVIRONMENT
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# LAYOUT APPLICATION.HTML.ERB
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

# README
markdown_file_content = <<-MARKDOWN
  Rails app generated based on the awesome [lewagon/rails-templates](https://github.com/lewagon/rails-templates) ([Le Wagon coding bootcamp](https://www.lewagon.com)).
MARKDOWN
file 'README.md', markdown_file_content, force: true

# GENERATORS
# ask an expert
# generators = <<-RUBY
#   config.generators do |generate|
#     generate.assets false
#     generate.helper false
#     generate.test_framework :test_unit, fixture: false
#   end
# RUBY

# environment generators

# AFTER BUNDLE
after_bundle do
  rails_command 'db:drop db:create db:migrate'

  generate('simple_form:install', '--bootstrap')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # ROUTES
  route "root to: 'pages#home'"

  # GIT IGNORE (after dotenv gem)
  append_file '.gitignore', <<-TXT
    .env*

    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # DEVISE
  generate('devise:install')
  generate('devise', 'User')
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<-RUBY
    class ApplicationController < ActionController::Base
      protect_from_forgery with: :exception
      before_action :authenticate_user!
    end
  RUBY
  rails_command 'db:migrate'
  generate('devise:views')
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<-RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [:home]
      def home
      end
    end
  RUBY

  # ENVIRONMENTS
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # WEBPACK & YARN
  run 'rm app/javascript/packs/application.js'
  run 'yarn add popper.js jquery bootstrap'
  file 'app/javascript/packs/applicaation.js', <<-JS
    import "bootstrap";
  JS

  inject_into_file 'config/webpack/environment.js', before: 'module.exports' do <<-'JS'
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
    ) 'JS'
  end

  # DOTENV
  run 'touch .env'

end

# RUBOCOP
run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

# GIT
git :init
git add: '.'
git commit: "-m 'Initial commit with devise template and RailsAdmin'"



