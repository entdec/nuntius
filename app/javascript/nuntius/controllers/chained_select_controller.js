import { Controller } from "@hotwired/stimulus"

// A select whose options follow another field of its form, by their
// data-chain: the template form's events and timestamps follow its object.
// When there are none for the field's value, the text target takes its place
// (a Custom event's scope#event), enabled instead of the select.
//
//   <div data-controller="nuntius--chained-select" data-nuntius--chained-select-to-value="template[klass]">
//     <div data-nuntius--chained-select-target="list"><select>...</select></div>
//     <div data-nuntius--chained-select-target="text"><input></div>
//   </div>
export default class extends Controller {
  static targets = ["list", "text"]
  static values = { to: String }

  connect() {
    this.select = this.listTarget.querySelector("select")
    this.options = Array.from(this.select.options)
    this.source = this.element.closest("form")?.querySelector(`[name="${this.toValue}"]`)
    this.boundChange = () => this.update(true)
    this.source?.addEventListener("change", this.boundChange)
    this.update(false)
  }

  disconnect() {
    this.source?.removeEventListener("change", this.boundChange)
  }

  update(changed) {
    const current = this.select.value
    const options = this.options.filter((option) => option.dataset.chain === this.source?.value)
    this.select.replaceChildren(...options)
    if (options.some((option) => option.value === current)) this.select.value = current

    const free = options.length === 0 && this.hasTextTarget
    this.toggle(this.listTarget, !free)
    if (this.hasTextTarget) this.toggle(this.textTarget, free)

    // Let what follows the select (the toggles for its kind) follow it too
    if (changed) this.select.dispatchEvent(new Event("change", { bubbles: true }))
  }

  toggle(element, on) {
    element.hidden = !on
    element.querySelectorAll("input, select").forEach((field) => (field.disabled = !on))
  }
}
