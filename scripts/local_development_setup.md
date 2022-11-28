# How to connect an app to refine-rails for local development

## Use local gem
edit the Gemfile to point to the local gem
```ruby
# Gemfile

# source "https://1Qa4UH-cEhG2Uv6SqqkplUbS8sICaT9OQ@gem.fury.io/hammerstonedev" do
#   gem "refine-rails"
# end
gem "refine-rails", path: "/home/rafe/code/hammerstone/refine-rails"
```

run bundle install
```sh
bundle install
```

## Use local npm package


Link the package from the refine rails folder
```sh
yarn link
```

Start a build watcher in the refine-rails folder
```sh
yarn build --watch
```

Switch to the app's folder and yarn link
```sh
yarn link '@hammerstone/refine-rails'
```

## Restart the Dev Server

```sh
bin/dev
```
