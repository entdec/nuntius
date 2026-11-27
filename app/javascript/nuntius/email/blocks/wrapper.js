import { background, border, padding } from "tess_edit/blocks/fields"
import { imageField } from "tess_edit/core/media"
import { backgroundImage, withBackgroundDefaults } from "nuntius/email/background"

export default {
  type: "wrapper",
  name: "Wrapper",
  kits: ["email"],
  icon: "wrapper",
  category: "layout",
  roles: ["wrapper"],
  accepts: ["body"],
  defaults: () => ({ attributes: { padding: "20px 0px", "background-color": "#ffffff" } }),
  fields: [
    { title: "Wrapper", fields: [background, imageField("attributes.background-url", "Background image", "data.background"), { key: "attributes.full-width", label: "Full width", type: "toggle", on: "full-width", off: "" }, padding] },
    backgroundImage,
    border
  ],
  palette: [
    {
      key: "wrapper",
      label: "Wrapper",
      create: ({ createNode }) => createNode("wrapper", { children: [createNode("section", { children: [createNode("column")] })] })
    }
  ],
  render: { mjml: (node, { container }) => container("mj-wrapper", withBackgroundDefaults(node)) }
}
