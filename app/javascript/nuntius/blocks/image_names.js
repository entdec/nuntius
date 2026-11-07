// Uploaded images are referred to by name (Nuntius::EmailImages): an image
// field keeps the image's name in its image key (data.image,
// data.background), and outside the editor its URL becomes Liquid that
// finds the image when the email is sent:
//
//   {{ 'logo.png' | image_url }}
//
// The editor's canvas shows the image from its URL, which Nuntius fills in
// when the editor opens.

import { getValue } from "tess_edit/core/document"
import { imageFields } from "tess_edit/core/media"

// The name of a field's uploaded image, if it has one
export function uploadedName(node, field) {
  const name = getValue(node, field.image)
  const source = getValue(node, field.source) || (name ? "upload" : "web")
  return source === "upload" && name ? String(name).replace(/'/g, "") : null
}

export function liquidImage(name, filter = "image_url") {
  return `{{ '${name}' | ${filter} }}`
}

// A block definition whose image fields refer to uploaded images by name
export function withImageNames(definition) {
  const fields = imageFields(definition)
  return {
    ...definition,
    render: {
      ...definition.render,
      mjml(node, ctx) {
        if (ctx.editor) return definition.render.mjml(node, ctx)

        const attributes = { ...node.attributes }
        for (const field of fields) {
          const name = uploadedName(node, field)
          if (name) attributes[field.key.split(".")[1]] = liquidImage(name)
        }
        return definition.render.mjml({ ...node, attributes }, ctx)
      }
    }
  }
}
