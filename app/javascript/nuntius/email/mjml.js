// An email's document → MJML. Each block renders itself through its
// render.mjml(node, ctx) hook: the email's own blocks (blocks/*.js), and
// TessEdit's, which the email kit takes in with theirs (render.js). This
// file holds the shared helpers in `ctx`.
//
// With { editor: true } the output is meant for the editing canvas: every
// element gets a css-class "tess-<id>" so clicks map back to blocks, empty
// containers get a placeholder ("tessph-<id>"), and Liquid tags are left out so
// loops and conditions show their content once.
//
// Without it, Loop and Condition blocks emit their Liquid tags inside <mj-raw>,
// which MJML copies into the HTML unchanged, so Liquid can run on the compiled HTML.
//
// The ctx a block's render.mjml gets:
//   editor              true when rendering for the canvas
//   context             where the node sits: "body" (mj-body, mj-wrapper),
//                       "section" (mj-section) or "column" (mj-column, mj-hero)
//   attrs(a, extra)     ` name="value"` pairs, empty values left out
//   cssClass(node)      { "css-class": "tess-<id> <the block's own css-class>" }
//                       in the editor, {} otherwise
//   element(tag, node, inner?)  <tag> with the node's attributes and class;
//                       self-closing without inner
//   container(tag, node)        <tag> around the node's rendered children
//   children(node, context?)    the children's MJML, as an array
//   liquid(node, open, close)   children wrapped in Liquid tags (not in the editor)
//   indent(text, level), escapeText, escapeAttribute, richText(content)

import { t } from "tess_edit/core/i18n"
import { getBlock } from "tess_edit/core/registry"
import { escapeAttribute, escapeText, richTextToHtml } from "tess_edit/export/richtext"

const PLACEHOLDER_COLOR = "#94a3b8"

function attrs(attributes = {}, extra = {}) {
  return Object.entries({ ...attributes, ...extra })
    .filter(([, value]) => value !== undefined && value !== null && value !== "")
    .map(([name, value]) => ` ${name}="${escapeAttribute(value)}"`)
    .join("")
}

function indent(text, level) {
  const pad = "  ".repeat(level)
  return text
    .split("\n")
    .map((line) => (line ? pad + line : line))
    .join("\n")
}

// What a container's children render as, from the roles it accepts.
function childContext(definition, context) {
  const accepts = definition?.accepts
  if (!Array.isArray(accepts)) return context
  if (accepts.includes("column")) return "section"
  if (accepts.includes("content")) return "column"
  return "body"
}

class Renderer {
  constructor(options) {
    this.editor = !!options.editor
  }

  // The marker class goes first, before the block's own css-class, so the
  // canvas finds blocks by the start of the class attribute.
  cssClass(node) {
    if (!this.editor) return {}
    return { "css-class": [`tess-${node.id}`, node.attributes?.["css-class"]].filter(Boolean).join(" ") }
  }

  children(node, context) {
    const kids = node.children || []
    if (!kids.length && this.editor) return [this.placeholder(node, context)]
    return kids.map((child) => this.node(child, context))
  }

  placeholder(node, context) {
    const text = t(context === "body" ? "Drop a section here" : context === "section" ? "Drop a column here" : "Drop content here")
    const mjText = `<mj-text css-class="tessph-${node.id}" align="center" color="${PLACEHOLDER_COLOR}" font-size="13px" padding="18px 25px">${text}</mj-text>`
    if (context === "column") return mjText
    if (context === "section") return `<mj-column css-class="tessph-${node.id}">\n  ${mjText}\n</mj-column>`
    return `<mj-section css-class="tessph-${node.id}">\n  <mj-column>\n    ${mjText}\n  </mj-column>\n</mj-section>`
  }

  context(context) {
    return {
      editor: this.editor,
      context,
      attrs,
      indent,
      escapeText,
      escapeAttribute,
      richText: richTextToHtml,
      cssClass: (node) => this.cssClass(node),
      children: (node, childCtx) => this.children(node, childCtx ?? childContext(getBlock(node.type), context)),
      element: (tag, node, inner) => {
        const open = `<${tag}${attrs(node.attributes, this.cssClass(node))}`
        return inner === undefined ? `${open} />` : `${open}>${inner}</${tag}>`
      },
      container: (tag, node) => {
        const inner = this.children(node, childContext(getBlock(node.type), context)).join("\n")
        return `<${tag}${attrs(node.attributes, this.cssClass(node))}>\n${indent(inner, 1)}\n</${tag}>`
      },
      liquid: (node, open, close) => {
        const inner = this.children(node, context)
        if (this.editor) return inner.join("\n")
        return [`<mj-raw>${open}</mj-raw>`, ...inner, `<mj-raw>${close}</mj-raw>`].join("\n")
      }
    }
  }

  node(node, context) {
    const render = getBlock(node.type)?.render?.mjml
    return render ? render(node, this.context(context)) : ""
  }
}

export function toMjml(doc, options = {}) {
  return new Renderer(options).node(doc, null)
}
