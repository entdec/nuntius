// A link to the email on the web, for when it doesn't show well in the inbox.
// Nuntius puts the message's URL in place of {{message_url}} after rendering
// the Liquid, so the raw tags keep Liquid from touching it.

import { linkFields, linkText } from "nuntius/blocks/link"

const TEXT = "View this email in your browser"

export default {
  type: "view_in_browser",
  name: "View in browser",
  icon: '<rect x="3" y="4" width="18" height="16" rx="2"/><path d="M3 9h18"/><circle cx="6" cy="6.5" r=".5"/>',
  category: "nuntius",
  roles: ["content"],
  defaults: () => ({ attributes: { align: "center", padding: "10px 25px", "font-size": "12px" }, data: { before: "", text: "" } }),
  fields: linkFields(TEXT),
  label: () => "View in browser",
  render: {
    mjml: (node, ctx) => linkText(node, ctx, "{% raw %}{{message_url}}{% endraw %}", TEXT)
  }
}
