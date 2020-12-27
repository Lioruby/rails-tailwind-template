# Rails Tailwind template

Quickly generate a rails app with Tailwind css library and the gem devise.
Thanks to Le Wagon : https://github.com/lewagon/rails-templates (same template with bootstrap )

# Get started

### Minimal
Get a minimal rails app ready to be deployed on Heroku with Tailwind, Simple form and debugging gems.

```sh
$ rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/lioruby/rails-tailwind-template/master/minimal.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## Minimal with rspec, factory_bot and shoulda-matchers gems
```sh
$ rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/lioruby/rails-tailwind-template/master/minimal_rspec_factory_bot.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

### Devise
Same as minimal plus a Devise install with a generated User model.

```sh
$ rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/lioruby/rails-tailwind-template/master/devise.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```

## Devise with rspec, factory_bot and shoulda-matchers gems
it generate a spec directly for the user model

```sh
$ rails new \
  --database postgresql \
  --webpack \
  -m https://raw.githubusercontent.com/lioruby/rails-tailwind-template/master/devise_rspec_factory_bot.rb \
  CHANGE_THIS_TO_YOUR_RAILS_APP_NAME
```
