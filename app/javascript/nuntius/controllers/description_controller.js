import { Controller } from "@hotwired/stimulus"

// A template's description, made from its form's sentence and conditions as
// they read: "Email when User activate, if User › State is active", while
// auto (its auto_description) is checked: when they change, or when there's
// no description yet. Typing one unchecks it, checking it makes it again.
// Parts of the sentence with data-description-skip are left out.
export default class extends Controller {
  static targets = ["field", "auto", "sentence"]
  static values = { if: String, and: String, or: String }

  connect() {
    this.schedule = this.schedule.bind(this)
    ;["change", "input", "click", "entdec--variable-picker:change"].forEach((type) => this.element.addEventListener(type, this.schedule))
    // The sentence's toggles put in their parts as they connect
    setTimeout(() => {
      this.composed = this.compose()
      if (!this.fieldTarget.value) this.fill()
    })
  }

  disconnect() {
    ;["change", "input", "click", "entdec--variable-picker:change"].forEach((type) => this.element.removeEventListener(type, this.schedule))
  }

  schedule(event) {
    if (event.target === this.fieldTarget) {
      if (event.type === "input" && event.isTrusted) this.autoTarget.checked = false
      return
    }
    // After the pills show what was chosen, when they read differently
    setTimeout(() => {
      const composed = this.compose()
      if (composed === this.composed) return

      this.composed = composed
      this.fill()
    })
  }

  fill() {
    if (this.autoTarget.checked) this.fieldTarget.value = this.compose()
  }

  compose() {
    const sentence = this.parts(this.sentenceTarget).join(" ")
    const rules = Array.from(this.element.querySelectorAll("[data-entdec--conditions-target='rule']"))
      .filter((rule) => rule.querySelector("[name$='[variable]']")?.value)
      .map((rule) => this.parts(rule).join(" "))
    if (!rules.length) return sentence

    const any = this.element.querySelector("[name$='[conditions][match]']")?.value === "any"
    return `${sentence}, ${this.ifValue} ${rules.join(` ${any ? this.orValue : this.andValue} `)}`
  }

  // The words, pills and fields shown, in order
  parts(root) {
    return Array.from(root.querySelectorAll("span, .entdec-pill-select__pill, input.entdec-pill-input"))
      .filter((node) => node.getClientRects().length && !node.closest("[data-description-skip]"))
      .filter((node) => !(node.tagName === "SPAN" && (node.children.length || node.closest(".entdec-pill-select"))))
      .map((node) => (node.tagName === "INPUT" ? node.value : node.querySelector("span")?.textContent || node.textContent).trim())
      .filter(Boolean)
  }
}
