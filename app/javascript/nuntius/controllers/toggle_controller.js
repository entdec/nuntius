import { Controller } from "@hotwired/stimulus"

// Shows the fields that go with an input's value, and only those, so the others aren't sent: the fields of each
// <template> whose data-toggle-value is the input's (or whose data-toggle-not-value isn't) are copied into the
// insertion target; hidden again, they go back into their template as they are, so what was typed in them is kept
// for when they're shown again (as Satis' toggle, which it replaces):
//
//   div data-controller="nuntius--toggle"
//     = f.check_box :specific, data: {"nuntius--toggle-target" => "input"}
//     div data-nuntius--toggle-target="insertion"
//     template data-nuntius--toggle-target="toggleable" data-toggle-value="true"
//       = f.text_area :description
//
// The input is a check box ("true" or "false"), radio buttons (the chosen one's value) or another field (its value).
export default class extends Controller {
  static targets = ["input", "insertion", "toggleable"]

  connect() {
    // A page from Turbo's cache has the copies it had then
    if (this.hasInsertionTarget) this.insertionTarget.replaceChildren()
    this.shown = new Map()
    this.update()
  }

  inputTargetConnected(input) {
    input.addEventListener("change", this.update)
  }

  inputTargetDisconnected(input) {
    input.removeEventListener("change", this.update)
  }

  // After the change has bubbled, so its other listeners see the fields as they were
  update = () => {
    setTimeout(() => this.toggle(this.value))
  }

  toggle(value) {
    if (!this.hasInsertionTarget) return

    this.toggleableTargets.forEach((template) => {
      const nodes = this.shown.get(template)
      if (!nodes || this.matches(template, value)) return

      template.content.replaceChildren(...nodes)
      this.shown.delete(template)
    })

    this.toggleableTargets.forEach((template, index) => {
      if (this.shown.has(template) || !this.matches(template, value)) return

      const nodes = Array.from(document.importNode(template.content, true).childNodes)
      const next = this.toggleableTargets.slice(index + 1).find((later) => this.shown.has(later))
      const before = next ? this.shown.get(next)[0] : null
      nodes.forEach((node) => this.insertionTarget.insertBefore(node, before))
      this.shown.set(template, nodes)
    })
  }

  matches(template, value) {
    const notValue = template.getAttribute("data-toggle-not-value")
    return template.getAttribute("data-toggle-value") == value || (notValue != null && notValue != value)
  }

  get value() {
    const input = this.inputTargets[0]
    if (!input) return undefined
    if (input.type == "radio") return this.inputTargets.find((radio) => radio.checked)?.value
    if (input.type == "checkbox") return input.checked ? "true" : "false"
    return input.value
  }
}
