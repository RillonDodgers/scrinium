# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "epubjs", to: "https://esm.sh/epubjs@0.3.93"
pin_all_from "app/javascript/controllers", under: "controllers"
