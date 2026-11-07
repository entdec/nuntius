// TessEdit's Image block, which can also send an uploaded image with the
// email instead of linking to it: its src becomes the embed_image filter
// with the image's signed id, which attaches it and refers to it by cid:.

import image from "tess_edit/blocks/image"
import { IMAGE_FIELD, imageSource } from "tess_edit/core/media"

const embed = {
  key: "data.embed",
  label: "Embed in the email",
  type: "toggle",
  on: true,
  off: false,
  hint: "Sends the image with every email instead of linking to it. Larger emails, but it shows without loading images.",
  visible: (node, editor) => imageSource(node, editor) === "upload"
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
      if (ctx.editor || node.data?.embed !== true || !node.data?.image) return image.render.mjml(node, ctx)

      const id = String(node.data.image).replace(/'/g, "")
      return image.render.mjml({ ...node, attributes: { ...node.attributes, src: `{{ '${id}' | embed_image }}` } }, ctx)
    }
  }
}
