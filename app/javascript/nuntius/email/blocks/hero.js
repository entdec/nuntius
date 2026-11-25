import { VERTICAL_ALIGN, background, padding } from "tess_edit/blocks/fields"
import { imageField } from "tess_edit/core/media"

const headline = { type: "doc", content: [{ type: "paragraph", content: [{ type: "text", text: "A big headline" }] }] }

export default {
  type: "hero",
  name: "Hero",
  kits: ["email"],
  icon: "hero",
  roles: ["body"],
  accepts: ["content"],
  defaults: () => ({
    attributes: {
      mode: "fixed-height",
      height: "320px",
      "background-url": "https://placehold.co/1200x640/1f2937/1f2937.png",
      "background-width": "600px",
      "background-height": "320px",
      "background-color": "#1f2937",
      "vertical-align": "middle",
      padding: "40px 0px"
    }
  }),
  fields: [
    {
      title: "Hero",
      fields: [
        { key: "attributes.mode", label: "Mode", type: "segmented", options: [{ value: "fixed-height", label: "Fixed height" }, { value: "fluid-height", label: "Fluid" }] },
        { key: "attributes.height", label: "Height", type: "size" },
        { key: "attributes.vertical-align", label: "Vertical align", type: "segmented", options: VERTICAL_ALIGN },
        padding
      ]
    },
    {
      title: "Background",
      fields: [
        imageField("attributes.background-url", "Image", "data.background"),
        { key: "attributes.background-width", label: "Image width", type: "size" },
        { key: "attributes.background-height", label: "Image height", type: "size" },
        { key: "attributes.background-position", label: "Position", type: "text", placeholder: "center center" },
        background
      ]
    }
  ],
  palette: [
    {
      key: "hero",
      label: "Hero",
      category: "layout",
      create: ({ createNode }) =>
        createNode("hero", {
          children: [
            createNode("text", { attributes: { align: "center", color: "#ffffff", "font-size": "32px", "font-weight": "700", padding: "10px 25px" }, data: { content: headline } }),
            createNode("button", { attributes: { align: "center", "background-color": "#ffffff", color: "#111827" }, data: { content: "Find out more" } })
          ]
        })
    }
  ],
  render: { mjml: (node, { container }) => container("mj-hero", node) }
}
