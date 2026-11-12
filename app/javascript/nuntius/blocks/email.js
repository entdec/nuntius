// A template's own settings in the email's root Inspect, besides its subject
// and preview text: when it sends (the template form's trigger sentence and
// conditions, and its Enabled again, as a slot, see app/views/nuntius/admin/templates/_trigger.html.slim),
// whom it sends to, its tracking and its layout. From, To and the tracking
// are part of the document (Concerns::EmailDesigned#assign_design), the
// slots are the form's own fields. Only in a template's editor, which says
// so in its options; a layout's has none of them.

import { extendBlock } from "tess_edit/core/registry"

const template = (node, editor) => Boolean(editor.options.template)

// "Account · created": the pills of the sentence as they are chosen. It is
// collapsed then, so what shows is what isn't hidden in it, not what's visible.
export function triggerSummary(element) {
  const hidden = (node) => {
    for (let parent = node; parent && parent !== element; parent = parent.parentElement) if (parent.hidden) return true
    return false
  }
  return Array.from(element.querySelectorAll(".nuntius-sentence select, .nuntius-sentence input.entdec-pill-input"))
    .filter((field) => !field.disabled && !hidden(field) && !field.closest("[data-description-skip]"))
    .map((field) => (field.tagName === "SELECT" ? field.selectedOptions[0]?.text : field.value)?.trim())
    .filter(Boolean)
    .join(" · ")
}

// Open at first when it has to be filled in or has errors
const open = (element) => element.hasAttribute("data-open") || Boolean(element.querySelector("[role=alert]"))

extendBlock("email", {
  fields: [
    {
      title: "When",
      before: "Message",
      fields: [{ key: "trigger", label: "Sends", type: "slot", slot: "trigger", summary: triggerSummary, open }]
    },
    {
      title: "Recipient",
      before: "Message",
      fields: [
        { key: "data.from", label: "From", type: "text", liquid: "output", visible: template, hint: "The provider's sender when empty." },
        { key: "data.to", label: "To", type: "text", liquid: "output", visible: template }
      ]
    },
    {
      title: "Tracking",
      before: "Layout",
      fields: [
        { key: "data.linkTracking", label: "Links", type: "toggle", on: true, off: false, visible: template },
        { key: "data.openTracking", label: "Opens", type: "toggle", on: true, off: false, visible: template }
      ]
    },
    {
      title: "Layout",
      fields: [{ key: "layout", label: "Template's layout", type: "slot", slot: "layout" }]
    }
  ]
})
