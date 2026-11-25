// An attachment of the email: a file on the web (https), or what a variable
// gives (contract.pdf: a stored file, what its drop makes, or a list of
// them). It renders as Nuntius' {% attach %} tag, which attaches it when the
// message is made; the email itself shows nothing of it. The editor shows
// it as a line with what it attaches.

import { t } from "tess_edit/core/i18n"

const PATH = /^[A-Za-z_][\w-]*(\.[\w-]+|\[\d+\])*$/
const URL = /^https?:\/\/[^\s'"{}%]+$/i

// The tag, or nothing while it attaches nothing that can be sent
export function attachTag(node) {
  const { source, url, variable } = node.data || {}
  if (source === "variable") {
    const path = (variable || "").trim()
    return PATH.test(path) ? `{% attach ${path} %}` : ""
  }
  const address = (url || "").trim()
  return URL.test(address) ? `{% attach '${address}' %}` : ""
}

function described(node) {
  const { source, url, variable } = node.data || {}
  const what = source === "variable" ? (variable || "").trim() : (url || "").trim().split("/").pop()
  return what ? t("Attachment: %{what}", { what }) : t("Attachment: choose a file or a variable")
}

const fromFile = (node) => node.data?.source !== "variable"
const fromVariable = (node) => node.data?.source === "variable"

export default {
  type: "attachment",
  name: "Attachment",
  kits: ["email"],
  icon: '<path d="M21.44 11.05l-9.19 9.19a6 6 0 0 1-8.49-8.49l9.19-9.19a4 4 0 0 1 5.66 5.66l-9.2 9.19a2 2 0 0 1-2.83-2.83l8.49-8.48"/>',
  category: "mailing",
  roles: ["content"],
  defaults: () => ({ data: { source: "file", url: "", variable: "" } }),
  fields: [
    {
      title: "Attachment",
      fields: [
        { key: "data.source", label: "From", type: "segmented", options: [{ value: "file", label: "A file" }, { value: "variable", label: "A variable" }] },
        { key: "data.url", label: "File", type: "text", placeholder: "https://example.com/terms.pdf", visible: fromFile, hint: "A file on the web, at an https address." },
        { key: "data.variable", label: "Variable", type: "text", liquid: "expression", placeholder: "contract.pdf", visible: fromVariable, hint: "What it gives is attached: a file, or a list of them. Nothing when it's empty." }
      ]
    }
  ],
  label: (node) => described(node),
  render: {
    mjml(node, { editor, context, escapeText }) {
      if (!editor) {
        const tag = attachTag(node)
        return tag ? `<mj-raw>${tag}</mj-raw>` : ""
      }
      // On the canvas only: what it attaches, as a line of its own
      const text = `<mj-text css-class="tess-${node.id}" padding="6px 25px" font-size="12px" color="#6b7280">📎 ${escapeText(described(node))}</mj-text>`
      return context === "column" ? text : `<mj-section padding="0px"><mj-column>${text}</mj-column></mj-section>`
    }
  }
}
