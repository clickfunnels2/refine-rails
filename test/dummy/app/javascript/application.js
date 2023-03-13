// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "@hammerstone/refine-rails"
import "controllers"

import jquery from "jquery"
window.jQuery = jquery
window.$ = jquery
