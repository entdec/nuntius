import { Controller } from "@hotwired/stimulus"

// A second input for a field of its form, kept in step with it both ways:
// a layout's name, as its card's title and in the email editor's Inspect.
// Its own input has no name, so only the form's field is submitted.
// A Satis switch says it changed with a change event on its hidden input.
//
//   <div data-controller="nuntius--mirror" data-nuntius--mirror-for-value="layout[name]">
//     …an input, or a Satis switch, without a name…
//   </div>
export default class extends Controller {
  static values = { for: String }

  connect() {
    this.own = this.element.querySelector("input:not([name]):not([type=checkbox])")
    this.field = this.element.closest("form")?.elements.namedItem(this.forValue)
    if (!this.own || !this.field) return

    this.fromOwn = (event) => this.copy(this.own, this.field, event.type)
    this.fromField = (event) => this.copy(this.field, this.own, event.type)
    for (const type of ["input", "change"]) {
      this.own.addEventListener(type, this.fromOwn)
      this.field.addEventListener(type, this.fromField)
    }
    this.copy(this.field, this.own, "change")
  }

  disconnect() {
    for (const type of ["input", "change"]) {
      this.own?.removeEventListener(type, this.fromOwn)
      this.field?.removeEventListener(type, this.fromField)
    }
  }

  copy(from, to, type) {
    if (to.value === from.value) return

    to.value = from.value
    to.dispatchEvent(new Event(type))
  }
}
