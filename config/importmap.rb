# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "jquery", to: "https://code.jquery.com/jquery-3.6.1.min.js", preload: true
pin "jquery-ujs", to: "https://ga.jspm.io/npm:jquery-ujs@1.2.3/src/rails.js", preload: true
pin "bootstrap", to: "bootstrap.min.js", preload: true
pin "popper", to: "popper.js", preload: true
pin_all_from "app/javascript/games", under: "games"
