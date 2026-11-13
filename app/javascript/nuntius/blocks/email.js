// A template's or campaign's own settings in the email's root Inspect,
// besides its subject and preview text: when it sends (a template's trigger
// sentence and conditions with its Enabled, see
// app/views/nuntius/admin/templates/_trigger.html.slim, or a campaign's
// publish at), a campaign's list and conditions, whom it sends to, its
// tracking and its layout. From, To and the tracking are part of the document
// (Concerns::EmailDesigned#assign_design), the slots are the form's own
// fields, always open. Only in a template's or campaign's editor, which says
// so in its options; a layout's has its name and description instead.

import { extendBlock } from "tess_edit/core/registry"

const template = (node, editor) => Boolean(editor.options.template)
const sends = (node, editor) => Boolean(editor.options.template || editor.options.campaign)

// Also the editors of the other transports' messages (kits/messages.js)
export const when = (before) => ({
  title: "When",
  before,
  fields: [{ key: "trigger", label: "", type: "slot", slot: "trigger" }]
})

// A campaign's list and conditions
export const audience = (before) => ({
  title: "Audience",
  before,
  fields: [{ key: "audience", label: "", type: "slot", slot: "audience" }]
})

export const recipient = (before) => ({
  title: "Recipient",
  before,
  fields: [
    { key: "data.from", label: "From", type: "text", liquid: "output", visible: sends, hint: "The provider's sender when empty." },
    { key: "data.to", label: "To", type: "text", liquid: "output", visible: template }
  ]
})

extendBlock("email", {
  fields: [
    when("Message"),
    audience("Message"),
    recipient("Message"),
    {
      title: "Tracking",
      before: "Layout",
      fields: [
        { key: "data.linkTracking", label: "Links", type: "toggle", on: true, off: false, visible: sends },
        { key: "data.openTracking", label: "Opens", type: "toggle", on: true, off: false, visible: sends }
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
