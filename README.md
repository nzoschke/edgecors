# CloudFront + Rails
## With asset pipeline, fonts and CORS

This demonstrates how to use CloudFront with Rails 5 and static assets like fonts, which require CORS.

This requires:

* Rails asset pipeline serving a custom font
* CloudFront configured to forward the `Origin` header
  * The [Edge addon](https://elements.heroku.com/addons/edge) provisions CloudFront with the correct settings
* rack-cors middleware whitelisting herokuapp.com and any custom domains

Resources:

* [Edge CDN addon docs](https://devcenter.heroku.com/articles/edge) to add CloudFront
* [Getting Started with Rails 5 guide](https://devcenter.heroku.com/articles/getting-started-with-rails5) to create a Rails app on Heroku
* [Using Fonts with Rails Asset Pipeline](https://stackoverflow.com/questions/10905905/using-fonts-with-rails-asset-pipeline) to set up a font
* [google/fonts](https://github.com/google/fonts) for open-source fonts
* [rack-cors](https://github.com/cyu/rack-cors) middleware
* [Configuring CloudFront to respect CORS settings](https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/header-caching.html#header-caching-web-cors)

## Development

### Create a Rails app

```shell
$ rails new edgecors --database=postgresql
$ cd edgecors
$ rails generate controller welcome
```

### Download a font to `app/assets/font`

```shell
# make the directory
$ mkdir -p app/assets/fonts
$ cd app/assets/fonts

# download the font
$ curl -LO https://github.com/google/fonts/raw/master/ofl/inconsolata/Inconsolata-Regular.ttf

# double check the file type
$ file Inconsolata-Regular.ttf
Inconsolata-Regular.ttf: TrueType font data
```

### Write CSS / SCSS

Add the font to your `app/assets/stylesheets/welcome.scss` file. Note the scss `font-url` helper.

```scss
@font-face {
  font-family: 'Inconsolata';
  src: font-url('Inconsolata-Regular.ttf') format('truetype');
  font-weight: normal;
  font-style: normal;
}

body {
  font-family: "Inconsolata";
}
```

### Verify in development server

```shell
$ rails server
$ open localhost:3000
```

You should see the custom font and a request to `http://localhost:3000/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf`

## Production

### Create a Heroku app with addon

```shell
$ heroku create edgecors

$ heroku addons:create edge
Creating edge on ⬢ edgecors... $5/month
Successfully configured https://d372g5jsa84e2.cloudfront.net
Created edge-reticulated-59593 as EDGE_AWS_ACCESS_KEY_ID, EDGE_AWS_SECRET_ACCESS_KEY, EDGE_DISTRIBUTION_ID, EDGE_URL
Use heroku addons:docs edge to view documentation
```

### Configure Asset Host

Configure Rails to serve assets from CloudFront in `config/environments/production.rb`:

```ruby
Rails.application.configure do
  config.action_controller.asset_host = ENV["EDGE_URL"]
end
```

### Push to Heroku

```shell
$ git push heroku master

remote: Building source:
remote: -----> Ruby app detected
remote: -----> Compiling Ruby/Rails
...

remote: -----> Preparing app for Rails asset pipeline
remote:        Running: rake assets:precompile
remote:        Yarn executable was not detected in the system.
remote:        Download Yarn at https://yarnpkg.com/en/docs/install
remote:        I, [2018-12-24T23:54:15.330217 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
remote:        I, [2018-12-24T23:54:15.330994 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf.gz
remote:        I, [2018-12-24T23:54:17.778848 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/application-9622f0fe63bfad91bdeaa3a771e86262263840678fd66849b311b6cfb3f7cc85.js
remote:        I, [2018-12-24T23:54:17.779473 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/application-9622f0fe63bfad91bdeaa3a771e86262263840678fd66849b311b6cfb3f7cc85.js.gz
remote:        I, [2018-12-24T23:54:17.795843 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/application-4b7c953bb1cc320178bce681bdb96c807c8c21628f6e8306768a0ecb0172dede.css
remote:        I, [2018-12-24T23:54:17.796264 #1369]  INFO -- : Writing /tmp/build_23f43cb401fa6841af82cb776163bc1b/public/assets/application-4b7c953bb1cc320178bce681bdb96c807c8c21628f6e8306768a0ecb0172dede.css.gz
remote:        Asset precompilation completed (3.62s)
remote:        Cleaning assets
remote:        Running: rake assets:clean
```

### Security warning on Heroku

```shell
$ heroku open
```

You **should not** see the custom font. You will see a request to `http://d1unsc88mkka3m.cloudfront.net/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf` with an error in the JavaScript Console:

```
Access to font at 'https://d1unsc88mkka3m.cloudfront.net/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf' from origin 'https://edgecors.herokuapp.com' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
edgecors.herokuapp.com/:1 GET https://d1unsc88mkka3m.cloudfront.net/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf net::ERR_FAILED
```

## CORS

### Add `rack/cors` middleware

Add to `Gemfile`:

```Gemfile
gem 'rack-cors', require: 'rack/cors'
```

```shell
$ bundle install
Fetching rack-cors 1.0.2
Installing rack-cors 1.0.2
```

Add to `config/application.rb`:

```ruby
module EdgeCors
  class Application < Rails::Application
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins %w[
          http://edgecors.herokuapp.com
          https://edgecors.herokuapp.com
          http://edgecors.mixable.net
          https://edgecors.mixable.net
        ]
        resource '/assets/*', headers: :any, methods: [:get, :post, :options]
      end
    end
  end
end
```

Note that `origins` contains variants of herokuapp and an [Edge custom domain](https://devcenter.heroku.com/articles/edge#custom-domain-setup). Also note there is no trailing slash on origins.

## Troubleshooting

You can look at the `Access-Control-Allow-Origin` header with `curl` commands:

```shell
$ curl --head -H "Origin: https://edgecors.herokuapp.com" http://localhost:3000/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://edgecors.herokuapp.com
Access-Control-Allow-Methods: GET, POST, OPTIONS

$ curl --head -H "Origin: https://edgecors.mixable.net" http://localhost:3000/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://edgecors.mixable.net
Access-Control-Allow-Methods: GET, POST, OPTIONS

$ curl --head -H "Origin: https://edgecors.mixable.net" http://localhost:3000/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://edgecors.mixable.net
Access-Control-Allow-Methods: GET, POST, OPTIONS

$ curl --head -H "Origin: https://example.com" http://localhost:3000/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
# No Access-Control-Allow-Origin header
```

CloudFront will cache the response based on `Origin` header. If it has the wrong value, create a CloudFront invalidation.

```shell
# First request is a miss
$ curl --head -H "Origin: https://edgecors.mixable.net" https://d1unsc88mkka3m.cloudfront.net/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
access-control-allow-origin: https://edgecors.mixable.net
access-control-allow-methods: GET, POST, OPTIONS
x-cache: Miss from cloudfront

# Subsequent are a hit
curl --head -H "Origin: https://edgecors.mixable.net" https://d1unsc88mkka3m.cloudfront.net/assets/Inconsolata-Regular-2a53b53d55363c4913a8873d0e1636d6c09d8a3c38570fb166fc71a5123ec8dc.ttf
access-control-allow-origin: https://edgecors.mixable.net
access-control-allow-methods: GET, POST, OPTIONS
x-cache: Hit from cloudfront
```
