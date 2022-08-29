// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails

import "@hotwired/turbo-rails"
import "jquery"
import "jquery-ujs"
import "bootstrap"
import "popper"
import { run, hidden_alert } from "games"

var app

$(document).on("turbo:load", () => {
  run(app)
})

$(document).bind("page:load ready", () => {
  hidden_alert()
})
