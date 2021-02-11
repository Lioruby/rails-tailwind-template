run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# GEMFILE
########################################
inject_into_file 'Gemfile', before: 'group :development, :test do' do
  <<~RUBY

    gem 'devise'
    gem 'autoprefixer-rails'
    gem 'font-awesome-sass'
    gem 'simple_form'
  RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY

    gem 'pry-byebug'
    gem 'pry-rails'
    gem 'dotenv-rails'
    gem 'rspec-rails', '~> 4.0.1'
    gem 'factory_bot_rails', '~> 6.1'
    gem 'shoulda-matchers', '~> 4.0'
  RUBY
end

# Procfile
########################################
file 'Procfile', <<~YAML
  web: bundle exec puma -C config/puma.rb
YAML

# Assets in javascript file
########################################
run 'mkdir app/javascript/stylesheets'
run 'touch app/javascript/stylesheets/application.scss'

# Dev environment
########################################
gsub_file('config/environments/development.rb', /config\.assets\.debug.*/, 'config.assets.debug = false')

# Layout
########################################
if Rails.version < "6"
  scripts = <<~HTML
    <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>
    <%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
    <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
  HTML
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>", scripts)
else
  gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
  inject_into_file 'app/views/layouts/application.html.erb', before: "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>" do
    <<~HTML
      <%= stylesheet_pack_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
    HTML
  end
end

gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)


# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :test_unit, fixture: false
  end
RUBY

environment generators

# Insert Devise flashes
file 'app/views/shared/_flashes.html.erb', <<~HTML
  <% if notice %>
    <div class="alert m-1" role="alert">
      <%= notice %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert m-1" role="alert">
      <%= alert %>
      <button type="button" class="close" data-dismiss="alert" aria-label="Close">
        <span aria-hidden="true">&times;</span>
      </button>
    </div>
  <% end %>
HTML

inject_into_file 'app/views/layouts/application.html.erb', after: "<%= yield %>" do
  <<-HTML
    <p><%= notice %></p>
    <p><%= alert %></p>
  HTML
end

########################################
# AFTER BUNDLE
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command 'db:drop db:create db:migrate'
  generate('simple_form:install')
  generate(:controller, 'pages', 'home', '--skip-routes', '--no-test-framework')

  # Routes
  ########################################
  route "root to: 'pages#home'"

  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*
    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install + user
  ########################################
  generate('devise:install')
  generate('devise', 'User')

    # Generators: rspec + rspec User model
  ######################################
  generate('rspec:install')
  generate('rspec:model user')

  # FACTORY BOT GEM
  # factory_bot.rb
  #####################################
  run 'mkdir ./spec/support'
  run 'touch ./spec/support/factory_bot.rb'
  insert_into_file './spec/support/factory_bot.rb' do
    <<~RUBY
      require 'factory_bot'

      RSpec.configure do |config|
        config.include FactoryBot::Syntax::Methods
      end
    RUBY
  end


  # rails_helper.rb
  gsub_file('./spec/rails_helper.rb', /.+/, '')

  insert_into_file './spec/rails_helper.rb' do
    <<~RUBY
      # This file is copied to spec/ when you run 'rails generate rspec:install'
      require 'spec_helper'
      ENV['RAILS_ENV'] ||= 'test'
      require File.expand_path('../config/environment', __dir__)
      # Prevent database truncation if the environment is production
      abort("The Rails environment is running in production mode!") if Rails.env.production?
      require 'rspec/rails'
      require 'support/factory_bot'

      Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |file| require file }

      begin
        ActiveRecord::Migration.maintain_test_schema!
      rescue ActiveRecord::PendingMigrationError => e
        puts e.to_s.strip
        exit 1
      end
      RSpec.configure do |config|
        # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
        config.include Warden::Test::Helpers

        config.use_transactional_fixtures = true

        config.infer_spec_type_from_file_location!

        # Filter lines from Rails gems in backtraces.
        config.filter_rails_from_backtrace!
        # arbitrary gems may also be filtered via:
        # config.filter_gems_from_backtrace("gem name")
      end

      Shoulda::Matchers.configure do |config|
        config.integrate do |with|
          with.test_framework :rspec
          with.library :rails
        end
      end

    RUBY
  end


  # Create factory user.rb
  run 'touch spec/support/user.rb'

  insert_into_file './spec/support/user.rb' do
    <<~RUBY
      FactoryBot.define do
        factory :user, class: 'User' do
          # Insert your user here
        end
      end
    RUBY
  end

  # Delete factories folder in './test/factories'
  run 'rm -rf ./test/factories'

  # App controller
  ########################################
  run 'rm app/controllers/application_controller.rb'
  file 'app/controllers/application_controller.rb', <<~RUBY
    class ApplicationController < ActionController::Base
    #{  "protect_from_forgery with: :exception\n" if Rails.version < "5.2"}  before_action :authenticate_user!
    end
  RUBY

  # migrate + devise views
  ########################################
  rails_command 'db:migrate'
  generate('devise:views')

  # Pages Controller
  ########################################
  run 'rm app/controllers/pages_controller.rb'
  file 'app/controllers/pages_controller.rb', <<~RUBY
    class PagesController < ApplicationController
      skip_before_action :authenticate_user!, only: [ :home ]
      def home
      end
    end
  RUBY

  # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: 'development'
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: 'production'

  # Webpacker / Yarn
  ########################################
  run 'yarn add tailwindcss@npm:@tailwindcss/postcss7-compat postcss@^7 autoprefixer@^9'
  append_file 'app/javascript/packs/application.js', <<~JS
    // ----------------------------------------------------
    // WRITE YOUR OWN JS STARTING FROM HERE 👇
    // ----------------------------------------------------
    // External imports

    // Internal imports, e.g:
    import '../stylesheets/application.scss';


    document.addEventListener('turbolinks:load', () => {
      // Call your functions here, e.g:
    });
  JS

  # Postcss.config.js
  ########################################

  gsub_file('./postcss.config.js', /.+/, '')

  inject_into_file './postcss.config.js' do
    <<~JS
      module.exports = {
        plugins: [
          require('postcss-import'),
          require('postcss-flexbugs-fixes'),
          require('postcss-preset-env')({
            autoprefixer: {
              flexbox: 'no-2009'
            },
            stage: 3
          }),
          require('tailwindcss'),
          require('autoprefixer'),
        ]
      };
    JS
  end

  # Create Tailwind.config.js file

  run 'touch tailwind.config.js'

  inject_into_file './tailwind.config.js' do
    <<~JS
      module.exports = {
        purge: [],
        darkMode: false, // or 'media' or 'class'
        theme: {
          extend: {},
        },
        variants: {
          extend: {},
        },
        plugins: [],
      };
    JS

  end

  # Include Tailwind in app

  inject_into_file 'app/javascript/stylesheets/application.scss' do
    <<~SCSS
      @import "tailwindcss/base";
      @import "tailwindcss/components";
      @import "tailwindcss/utilities";

      .alert {
        position: fixed;
        bottom: 8px;
        right: 8px;
        z-index: 1000;
        background-color: #F7F4EA;
        padding: 4px;
        font-size: 10px;
        border-radius: 2px;
      }
    SCSS
  end

  # Include FontAwesome in app
  inject_into_file 'app/assets/stylesheets/application.scss' do
    <<~SCSS
      @import "font-awesome-sprockets";
      @import "font-awesome";
    SCSS
  end

  # Dotenv
  ########################################
  run 'touch .env'

  # Rubocop
  ########################################
  run 'curl -L https://raw.githubusercontent.com/lewagon/rails-templates/master/.rubocop.yml > .rubocop.yml'

  # Git
  ########################################
  git add: '.'
  git commit: "-m 'Initial commit'"

  # Fix puma config
  gsub_file('config/puma.rb', 'pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }', '# pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }')
end
