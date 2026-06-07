import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["audio", "time"]
  static values = {
    progressUrl: String,
    position: Number,
    mode: String
  }

  connect() {
    this.restored = false
    this.saveTimer = null
  }

  disconnect() {
    clearTimeout(this.saveTimer)
  }

  restore() {
    if (this.restored || !this.positionValue) return

    this.audioTarget.currentTime = this.positionValue
    this.restored = true
    this.updateTime()
  }

  back() {
    this.audioTarget.currentTime = Math.max(0, this.audioTarget.currentTime - 15)
    this.saveNow()
  }

  forward() {
    this.audioTarget.currentTime = Math.min(this.audioTarget.duration || Infinity, this.audioTarget.currentTime + 15)
    this.saveNow()
  }

  setSpeed(event) {
    this.audioTarget.playbackRate = Number(event.target.value)
  }

  saveNow() {
    this.updateTime()
    clearTimeout(this.saveTimer)
    this.saveTimer = setTimeout(() => this.save(), 1000)
  }

  save() {
    if (!Number.isFinite(this.audioTarget.currentTime)) return

    const body = new URLSearchParams({
      audio_position_seconds: this.audioTarget.currentTime.toString(),
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

  updateTime() {
    if (!this.hasTimeTarget) return

    this.timeTarget.textContent = this.formatTime(this.audioTarget.currentTime || 0)
  }

  formatTime(seconds) {
    const total = Math.floor(seconds)
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor((total % 3600) / 60).toString().padStart(2, "0")
    const remainingSeconds = (total % 60).toString().padStart(2, "0")

    return `${hours}:${minutes}:${remainingSeconds}`
  }
}
