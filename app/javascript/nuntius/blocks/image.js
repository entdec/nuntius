// TessEdit's Image block, with uploaded images referred to by name (see
// image_names.js). It can also send an uploaded image with the email
// instead of linking to it: its src becomes the embed_image filter, which
// attaches it and refers to it by cid:.

import image from "tess_edit/blocks/image"
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
// PDF kit) use this Image block too. An email's root is a "root" block.
function inEmail(editor) {
  return !editor?.doc || editor.doc.type === "root"
}

function withEmbed(group, index) {
  if (index !== 0) return group
  const fields = [...group.fields]
  fields.splice(fields.findIndex((field) => field.key === IMAGE_FIELD.key) + 1, 0, embed)
  return { ...group, fields }
}

export default {
  ...image,
  fields: image.fields.map(withEmbed),
  render: {
    mjml(node, ctx) {
      // The editor's canvas shows the image from its URL
      const name = !ctx.editor && uploadedName(node, IMAGE_FIELD)
      if (!name) return image.render.mjml(node, ctx)

      const filter = node.data?.embed === true ? "embed_image" : "image_url"
      return image.render.mjml({ ...node, attributes: { ...node.attributes, src: liquidImage(name, filter) } }, ctx)
    }
  }
}
