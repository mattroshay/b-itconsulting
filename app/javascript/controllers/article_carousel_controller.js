import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide", "indicator"]
  static values = { index: Number }

  connect() {
    if (Number.isNaN(this.indexValue)) {
      this.indexValue = 0
    }

    if (this.slideTargets.length) {
      this.show(this.indexValue)
    }
  }

  next(event) {
    event.preventDefault()
    this.show(this.indexValue + 1)
  }

  prev(event) {
    event.preventDefault()
    this.show(this.indexValue - 1)
  }

  go(event) {
    event.preventDefault()
    const { index } = event.currentTarget.dataset
    this.show(Number(index))
  }

  show(index) {
    const total = this.slideTargets.length
    if (!total) return

    const normalized = (index + total) % total
    this.indexValue = normalized

    this.slideTargets.forEach((el, idx) => {
      const isActive = idx === normalized
      el.classList.toggle("is-active", isActive)
      el.toggleAttribute("hidden", !isActive)
      el.setAttribute("aria-hidden", (!isActive).toString())
    })

    this.indicatorTargets.forEach((el, idx) => {
      const isActive = idx === normalized
      el.classList.toggle("is-active", isActive)
      el.setAttribute("aria-current", isActive ? "true" : "false")
    })
  }
}

