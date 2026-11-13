// A template's own settings in the email's root Inspect, besides its subject
// and preview text: when it sends (the template form's trigger sentence and
// conditions, and its Enabled, as a slot that's always open, see
// app/views/nuntius/admin/templates/_trigger.html.slim),
// whom it sends to, its tracking and its layout. From, To and the tracking
// are part of the document (Concerns::EmailDesigned#assign_design), the
// slots are the form's own fields. Only in a template's editor, which says
// so in its options; a layout's has its name and description instead.

import { extendBlock } from "tess_edit/core/registry"

const template = (node, editor) => Boolean(editor.options.template)

// Also the editors of the other transports' messages (kits/messages.js)
export const when = (before) => ({
  title: "When",
  before,
  fields: [{ key: "trigger", label: "", type: "slot", slot: "trigger" }]
})

export const recipient = (before) => ({
  title: "Recipient",
  before,
  fields: [
    { key: "data.from", label: "From", type: "text", liquid: "output", visible: template, hint: "The provider's sender when empty." },
    { key: "data.to", label: "To", type: "text", liquid: "output", visible: template }
  ]
})

extendBlock("email", {
  fields: [
    when("Message"),
    recipient("Message"),
    {
      title: "Tracking",
      before: "Layout",
      fields: [
        { key: "data.linkTracking", label: "Links", type: "toggle", on: true, off: false, visible: template },
        { key: "data.openTracking", label: "Opens", type: "toggle", on: true, off: false, visible: template }
      ]
    },
    // A layout's own name (also its card's title) and description
    {
      title: "Details",
      before: "Message",
      fields: [
        { key: "name", label: "Name", type: "slot", slot: "name" },
        { key: "description", label: "Description", type: "slot", slot: "description" }
      ]
    },
    {
      title: "Layout",
      fields: [{ key: "layout", label: "Template's layout", type: "slot", slot: "layout" }]
    }
  ]
})
