import { Controller } from "@hotwired/stimulus"

// The variables of the class chosen in a form (a template's): urls has the
// variables URL for each class, for the form field named by for. Choosing
// another class points the variable pickers, Liquid fields and email editor
// inside it at that class's variables, also those in templates still to be added.
const URLS = ["data-entdec--variable-picker-url-value", "data-entdec--liquid-field-url-value", "data-tess-edit-variables-url-value"]

export default class extends Controller {
  static values = { urls: Object, for: String }

  connect() {
    this.field = this.element.closest("form")?.elements.namedItem(this.forValue)
    if (!this.field) return

    this.switch = this.switch.bind(this)
    this.field.addEventListener("change", this.switch)
    this.switch()
  }

  disconnect() {
    this.field?.removeEventListener("change", this.switch)
  }

  switch() {
    const url = this.urlsValue[this.field.value]
    if (url) this.point(this.element, url)
  }

  point(root, url) {
    const selector = URLS.map((attribute) => `[${attribute}]`).join(", ")
    root.querySelectorAll(selector).forEach((element) => {
      URLS.forEach((attribute) => element.hasAttribute(attribute) && element.setAttribute(attribute, url))
    })
    root.querySelectorAll("template").forEach((template) => this.point(template.content, url))
  }
}
