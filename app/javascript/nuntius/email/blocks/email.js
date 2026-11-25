// The root of an email: renders the whole <mjml> document, with the
// email's subject, preview text and theme in <mj-head>.

export default {
  type: "email",
  name: "Email",
  kits: ["email"],
  icon: "root",
  roles: [],
  accepts: ["body", "wrapper"],
  defaults: () => ({
    attributes: { width: "600px", "background-color": "#f3f4f6" },
    data: {
      subject: "",
      preheader: "",
      breakpoint: "480px",
      fontFamily: "Helvetica, Arial, sans-serif",
      fontSize: "14px",
      lineHeight: "1.6",
      textColor: "#111827",
      css: ""
    }
  }),
  fields: [
    {
      title: "Message",
      fields: [
        { key: "data.subject", label: "Subject", type: "text", liquid: true },
        { key: "data.preheader", label: "Preview text", type: "text", liquid: true, hint: "Shown after the subject in most inboxes." }
      ]
    },
    {
      title: "Layout",
      fields: [
        { key: "attributes.width", label: "Width", type: "size", placeholder: "600px" },
        { key: "data.breakpoint", label: "Breakpoint", type: "size", placeholder: "480px", hint: "Below this width columns stack." },
        { key: "attributes.background-color", label: "Background", type: "color" }
      ]
    },
    {
      title: "Theme",
      fields: [
        { key: "data.fontFamily", label: "Font family", type: "font" },
        { key: "data.fontSize", label: "Font size", type: "size" },
        { key: "data.lineHeight", label: "Line height", type: "text" },
        { key: "data.textColor", label: "Text color", type: "color" }
      ]
    },
    {
      title: "Custom CSS",
      collapsed: true,
      fields: [{ key: "data.css", label: "CSS", type: "code", language: "css", hint: "Added to the email's <style> block." }]
    }
  ],
  render: {
    mjml(node, { attrs, cssClass, children, indent, escapeText, escapeAttribute }) {
      const d = node.data || {}
      const head = []
      if (d.subject) head.push(`<mj-title>${escapeText(d.subject)}</mj-title>`)
      if (d.preheader) head.push(`<mj-preview>${escapeText(d.preheader)}</mj-preview>`)
      if (d.breakpoint) head.push(`<mj-breakpoint width="${escapeAttribute(d.breakpoint)}" />`)
      head.push(
        [
          "<mj-attributes>",
          `  <mj-all${attrs({ "font-family": d.fontFamily })} />`,
          `  <mj-text${attrs({ "font-size": d.fontSize, "line-height": d.lineHeight, color: d.textColor })} />`,
          "</mj-attributes>"
        ].join("\n")
      )
      if (d.css) head.push(`<mj-style>\n${d.css}\n</mj-style>`)

      return [
        "<mjml>",
        "  <mj-head>",
        indent(head.join("\n"), 2),
        "  </mj-head>",
        `  <mj-body${attrs(node.attributes, cssClass(node))}>`,
        indent(children(node, "body").join("\n"), 2),
        "  </mj-body>",
        "</mjml>"
      ].join("\n")
    }
  }
}
