import { align } from "tess_edit/blocks/fields"

export default {
  type: "navbar",
  name: "Navbar",
  kits: ["email"],
  icon: "navbar",
  category: "content",
  roles: ["content"],
  defaults: () => ({
    attributes: { align: "center" },
    data: {
      links: [
        { label: "Home", href: "https://example.com/" },
        { label: "Products", href: "https://example.com/products" },
        { label: "Contact", href: "https://example.com/contact" }
      ],
      color: "#111827",
      fontSize: "14px",
      linkPadding: "10px 15px"
    }
  }),
  fields: [
    {
      title: "Navbar",
      fields: [
        { key: "data.links", label: "Links", type: "list", item: [{ name: "label", label: "Label" }, { name: "href", label: "URL" }], newItem: { label: "Link", href: "https://" } },
        align,
        { key: "attributes.hamburger", label: "Hamburger on mobile", type: "toggle", on: "hamburger", off: "" }
      ]
    },
    {
      title: "Links",
      fields: [
        { key: "data.color", label: "Color", type: "color" },
        { key: "data.fontSize", label: "Font size", type: "size" },
        { key: "data.fontFamily", label: "Font family", type: "font", placeholder: "Inherit" },
        { key: "data.linkPadding", label: "Padding", type: "spacing" }
      ]
    }
  ],
  render: {
    mjml(node, { element, attrs, escapeText }) {
      const d = node.data
      const linkAttrs = { color: d.color, "font-size": d.fontSize, "font-family": d.fontFamily, padding: d.linkPadding }
      const links = (d.links || []).map((link) => `  <mj-navbar-link${attrs({ href: link.href, ...linkAttrs })}>${escapeText(link.label)}</mj-navbar-link>`)
      return element("mj-navbar", node, `\n${links.join("\n")}\n`)
    }
  }
}
