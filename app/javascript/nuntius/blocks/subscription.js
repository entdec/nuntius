// A link to the subscriber's page, where they manage their subscription or
// unsubscribe. Only campaigns have subscribers: in a template the block
// renders nothing. Campaigns to lists that allow unsubscribing need one.

import { linkFields, linkText } from "nuntius/blocks/link"

const TEXT = "Manage your subscription"

export default {
  type: "subscription",
  name: "Manage subscription",
  icon: '<circle cx="9" cy="8" r="3.5"/><path d="M3 20a6 6 0 0 1 12 0"/><path d="M16 11h5"/>',
  category: "mailing",
  roles: ["content"],
  defaults: () => ({ attributes: { align: "center", padding: "10px 25px", "font-size": "12px" }, data: { before: "", text: "" } }),
  fields: linkFields(TEXT),
  hint: "Only shown in campaigns, where it links to the subscriber's page.",
  label: () => "Manage subscription",
  render: {
    mjml(node, ctx) {
      const text = linkText(node, ctx, "{{ subscriber_url }}", TEXT)
      if (ctx.editor) return text
      return ["<mj-raw>{% if subscriber_url %}</mj-raw>", text, "<mj-raw>{% endif %}</mj-raw>"].join("\n")
    }
  }
}
