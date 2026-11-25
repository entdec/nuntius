// TessEdit's Image block, with uploaded images referred to by name (see
// image_names.js). It can also send an uploaded image with the email
// instead of linking to it: its src becomes the embed_image filter, which
// attaches it and refers to it by cid:.

import image from "tess_edit/blocks/image"
import { getBlock, kitOf } from "tess_edit/core/registry"
import { mjml as emailMjml } from "nuntius/email/render"
import { IMAGE_FIELD, imageSource } from "tess_edit/core/media"
import { liquidImage, uploadedName } from "nuntius/blocks/image_names"

const embed = {
  key: "data.embed",
  label: "Embed in the email",
  type: "toggle",
  on: true,
  off: false,
  hint: "Sends the image with every email instead of linking to it. Larger emails, but it shows without loading images.",
  visible: (node, editor) => inEmail(editor) && imageSource(node, editor) === "upload"
}

// Only an email can embed an image: TessEdit's other kits (e.g. a host app's
// PDF kit) use this Image block too.
function inEmail(editor) {
  return !editor?.doc || kitOf(editor.doc)?.key === "email"
}

function withEmbed(group, index) {
  if (index !== 0) return group
  const fields = [...group.fields]
  fields.splice(fields.findIndex((field) => field.key === IMAGE_FIELD.key) + 1, 0, embed)
  return { ...group, fields }
}

// Registered in place of TessEdit's, so it keeps the kits and render hooks
// the Image block has by then, such as the email's (nuntius/email)
export default function nuntiusImage(registered = getBlock("image")) {
  return {
    ...image,
    kits: registered?.kits || ["email"],
    fields: image.fields.map(withEmbed),
    render: {
      ...registered?.render,
      mjml(node, ctx) {
        // The editor's canvas shows the image from its URL
        const name = !ctx.editor && uploadedName(node, IMAGE_FIELD)
        if (!name) return emailMjml.image(node, ctx)

        const filter = node.data?.embed === true ? "embed_image" : "image_url"
        return emailMjml.image({ ...node, attributes: { ...node.attributes, src: liquidImage(name, filter) } }, ctx)
      }
    }
  }
}
