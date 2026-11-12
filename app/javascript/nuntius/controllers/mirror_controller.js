import { Controller } from "@hotwired/stimulus"

// A second switch for a field of its form, kept in step with it both ways:
// a template's Enabled, in the card's actions and in the email editor's When.
// Its own hidden input has no name, so only the form's field is submitted.
// Satis's switch says it changed with a change event on its hidden input.
//
//   <div data-controller="nuntius--mirror" data-nuntius--mirror-for-value="template[enabled]">
//     …a Satis switch whose hidden input has no name…
//   </div>
export default class extends Controller {
  static values = { for: String }

  connect() {
    this.own = this.element.querySelector("input[type=hidden]:not([name])")
    this.field = this.element.closest("form")?.elements.namedItem(this.forValue)
    if (!this.own || !this.field) return

    this.fromOwn = () => this.copy(this.own, this.field)
    this.fromField = () => this.copy(this.field, this.own)
    this.own.addEventListener("change", this.fromOwn)
    this.field.addEventListener("change", this.fromField)
    this.fromField()
  }

  disconnect() {
    this.own?.removeEventListener("change", this.fromOwn)
    this.field?.removeEventListener("change", this.fromField)
  }

  copy(from, to) {
    if (to.value === from.value) return

    to.value = from.value
    to.dispatchEvent(new Event("change"))
  }
}
