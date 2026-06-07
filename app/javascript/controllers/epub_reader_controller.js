import { Controller } from "@hotwired/stimulus"
import ePub from "epubjs"

export default class extends Controller {
  static targets = ["viewer", "error"]
  static values = {
    url: String,
    progressUrl: String,
    location: String,
    mode: String
  }

  connect() {
    this.saveTimer = null
    this.book = ePub(this.urlValue)
    this.rendition = this.book.renderTo(this.viewerTarget, {
      width: "100%",
      height: "100%",
      flow: "paginated"
    })

    this.rendition.display(this.locationValue || undefined).catch(() => this.showError("Could not open EPUB."))
    this.rendition.on("relocated", (location) => this.scheduleSave(location.start.cfi))
  }

  disconnect() {
    clearTimeout(this.saveTimer)
    this.rendition?.destroy()
    this.book?.destroy()
  }

  previous() {
    this.rendition?.prev()
  }

  next() {
    this.rendition?.next()
  }

  scheduleSave(location) {
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.save(location), 750)
  }

  save(location) {
    const body = new URLSearchParams({
      epub_location: location,
      last_mode: this.modeValue
    })

    fetch(this.progressUrlValue, {
      method: "PATCH",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content
      },
      body
    })
  }

  showError(message) {
    if (!this.hasErrorTarget) return

    this.errorTarget.textContent = message
    this.errorTarget.classList.remove("hidden")
  }
}
