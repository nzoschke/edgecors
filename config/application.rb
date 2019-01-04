require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

class Loggo
  def initialize(app)
    @app = app
  end
  def call(env)
    puts env.select { |k,v|
      k.match("^HTTP.*|^CONTENT.*|^REMOTE.*|^REQUEST.*|^AUTHORIZATION.*|^SCRIPT.*|^SERVER.*")
    }
    @app.call(env)
  end
end

module EdgeCors
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.middleware.insert_after ActionDispatch::Static, Rack::Deflater

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins %w[
          http://edgecors.herokuapp.com
          https://edgecors.herokuapp.com
          http://edgecors.mixable.net
          https://edgecors.mixable.net
        ]
        resource "*", headers: :any, methods: [:get, :post, :options]
      end
    end

    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=31536000'
    }

    config.middleware.insert_before 0, Loggo
  end
end

