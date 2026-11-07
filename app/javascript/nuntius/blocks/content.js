// Where the templates and campaigns using a layout put their own content.
// What a layout has inside it is example content to design the layout with;
// a template or campaign replaces it with its own. A layout has exactly one.
//
// Outside the editor its contents are marked with two comments, which
// Nuntius::EmailDesign uses to put a template's content into its layout.

export const CONTENT_START = "<mj-raw><!-- nuntius:content --></mj-raw>"
export const CONTENT_END = "<mj-raw><!-- /nuntius:content --></mj-raw>"

export default {
  type: "content",
  name: "Content",
  icon: '<rect x="3" y="4" width="18" height="16" rx="2" stroke-dasharray="3 2"/><path d="M7 9h10M7 13h10M7 17h6"/>',
  category: "layout",
  // Like Loop and Condition it adds no HTML of its own and takes what its
  // parent takes, so it works at the top level and inside a column.
  roles: ["body", "content"],
  accepts: "inherit",
  defaults: () => ({ attributes: {}, data: {} }),
  fields: [],
  hint: "The content of the templates and campaigns using this layout goes here. What you put inside is example content for designing the layout.",
  label: () => "Content",
  render: {
    mjml(node, { editor, children }) {
      const inner = children(node)
      return editor ? inner.join("\n") : [CONTENT_START, ...inner, CONTENT_END].join("\n")
    }
  }
}
