// How TessEdit's own blocks render in an email: their MJML, the email kit's
// render.mjml hooks, added with extendBlock (see kit.js). The email's own
// blocks (blocks/*.js) have theirs in their definitions.

import { extendBlock } from "tess_edit/core/registry"
import { CONTENT_END, CONTENT_START } from "tess_edit/blocks/content"
import { forTag } from "tess_edit/blocks/loop"
import { ifTag } from "tess_edit/blocks/condition"
import { assignTag } from "tess_edit/blocks/assign"
import { tableHtml } from "tess_edit/export/table"

const mjRaw = (html) => `<mj-raw>${html}</mj-raw>`

export const mjml = {
  section: (node, { container }) => container("mj-section", node),
  column: (node, { container }) => container("mj-column", node),
  text: (node, { element, richText }) => element("mj-text", node, richText(node.data.content)),
  image: (node, { element }) => element("mj-image", node),
  button: (node, { element, escapeText }) => element("mj-button", node, escapeText(node.data.content)),
  divider: (node, { element }) => element("mj-divider", node),
  spacer: (node, { element }) => element("mj-spacer", node),
  raw(node, { editor, context }) {
    const html = node.data.html || ""
    if (!editor) return mjRaw(html)
    // mj-raw output cannot carry a class, so the canvas shows it inside a text block.
    const text = `<mj-text css-class="tess-${node.id}" padding="0px">${html}</mj-text>`
    return context === "column" ? text : `<mj-section padding="0px"><mj-column>${text}</mj-column></mj-section>`
  },
  loop: (node, { liquid }) => liquid(node, forTag(node), "{% endfor %}"),
  condition: (node, { liquid }) => liquid(node, ifTag(node), "{% endif %}"),
  assign: (node, { editor }) => (editor ? "" : mjRaw(assignTag(node))),
  // The markers in <mj-raw> tags, which MJML keeps (TessEdit::Content finds them there)
  content(node, { editor, children }) {
    const inner = children(node)
    return editor ? inner.join("\n") : [mjRaw(CONTENT_START), ...inner, mjRaw(CONTENT_END)].join("\n")
  },
  // An mj-table, which MJML copies as it is, so its cells' blocks are HTML
  // (tableHtml), not MJML; rows and cells render in their table's
  table: (node, ctx) => ctx.element("mj-table", node, tableHtml(node, ctx)),
  table_row: () => "",
  table_cell: () => ""
}

// In an email only: a section as wide as the inbox, its background too
const fullWidth = { title: "Section", fields: [{ key: "attributes.full-width", label: "Full width", type: "toggle", on: "full-width", off: "", visible: (node, editor) => editor?.kit?.key === "email" }] }

export function extendTessEditBlocks() {
  for (const [type, hook] of Object.entries(mjml)) {
    extendBlock(type, { kits: ["email"], render: { mjml: hook }, fields: type === "section" ? [fullWidth] : [] })
  }
}
