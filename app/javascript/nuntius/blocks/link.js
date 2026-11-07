// Shared by the View in browser and Manage subscription blocks: a line of
// text with a link whose URL Nuntius fills in when it sends.

import { align, padding, typography } from "tess_edit/blocks/fields"

export function linkFields(defaultText) {
  return [
    {
      title: "Link",
      fields: [
        { key: "data.before", label: "Text before the link", type: "text", placeholder: "Optional" },
        { key: "data.text", label: "Link text", type: "text", placeholder: defaultText },
        align,
        padding
      ]
    },
    typography()
  ]
}

// <mj-text> with the text before the link and the link, which doesn't take
// part in link tracking.
export function linkText(node, { element, escapeText, escapeAttribute }, url, defaultText) {
  const { before, text } = node.data || {}
  const link = `<a href="${escapeAttribute(url)}" data-nuntius-tracking="false" style="color:inherit;text-decoration:underline;">${escapeText(text || defaultText)}</a>`
  return element("mj-text", node, before ? `${escapeText(before)} ${link}` : link)
}
