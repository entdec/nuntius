import { Controller } from "@hotwired/stimulus"

// The tabs of an admin page's default frame (shared/_page): one panel at a time, the one with an error in it first
//
//   div data-controller="nuntius--tabs"
//     button data-nuntius--tabs-target="tab" data-action="nuntius--tabs#select"
//     div data-nuntius--tabs-target="panel"
export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    const withError = this.panelTargets.findIndex((panel) => panel.querySelector("[role=alert], [aria-invalid=true]"))
    if (withError > 0) this.show(withError)
  }

  select(event) {
    this.show(this.tabTargets.indexOf(event.currentTarget))
  }

  show(index) {
    this.tabTargets.forEach((tab, i) => tab.setAttribute("aria-selected", i === index))
    this.panelTargets.forEach((panel, i) => (panel.hidden = i !== index))
  }
}
