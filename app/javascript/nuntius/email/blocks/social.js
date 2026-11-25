import { align, padding, typography } from "tess_edit/blocks/fields"

export default {
  type: "social",
  name: "Social",
  kits: ["email"],
  icon: "social",
  category: "content",
  roles: ["content"],
  defaults: () => ({
    attributes: { mode: "horizontal", align: "center", "icon-size": "24px", padding: "10px 25px" },
    data: {
      elements: [
        { name: "facebook", href: "https://facebook.com/", label: "" },
        { name: "instagram", href: "https://instagram.com/", label: "" },
        { name: "linkedin", href: "https://linkedin.com/", label: "" }
      ]
    }
  }),
  fields: [
    {
      title: "Social",
      fields: [
        { key: "data.elements", label: "Links", type: "list", item: [{ name: "name", label: "Network", type: "select", options: ["facebook", "instagram", "linkedin", "x", "youtube", "github", "pinterest", "web"] }, { name: "href", label: "URL" }, { name: "label", label: "Label" }], newItem: { name: "web", href: "https://", label: "" } },
        { key: "attributes.mode", label: "Mode", type: "segmented", options: [{ value: "horizontal", label: "Horizontal" }, { value: "vertical", label: "Vertical" }] },
        { key: "attributes.icon-size", label: "Icon size", type: "size" },
        { key: "attributes.icon-padding", label: "Icon padding", type: "spacing" },
        align,
        padding
      ]
    },
    typography()
  ],
  render: {
    mjml(node, { element, attrs, escapeText }) {
      const elements = (node.data.elements || []).map((item) => `  <mj-social-element${attrs({ name: item.name, href: item.href })}>${escapeText(item.label)}</mj-social-element>`)
      return element("mj-social", node, `\n${elements.join("\n")}\n`)
    }
  }
}
