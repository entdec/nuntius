// Nuntius' Image block: TessEdit's, with the option to embed an uploaded image.
import { test } from "node:test"
import assert from "node:assert/strict"
import { createDocument, createNode, insert } from "tess_edit/core/document"
import { createFromPalette } from "tess_edit/core/document"
import { getBlock, registerBlock } from "tess_edit/core/registry"
import { toMjml } from "tess_edit/export/mjml"
import image from "nuntius/blocks/image"

registerBlock(image)

function emailWith(data) {
  const doc = createDocument()
  const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
  insert(doc, section.children[0].id, 0, createNode("image", { attributes: { src: "https://app.example.com/rails/active_storage/blobs/abc/logo.png" }, data }))
  return doc
}

test("an embedded image is sent with the email through embed_image", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "eyJfcmFpbHMi--1f2e", embed: true }))

  assert.match(mjml, /<mj-image[^>]* src="\{\{ 'eyJfcmFpbHMi--1f2e' \| embed_image \}\}"/)
})

test("the editor's canvas shows an embedded image from its URL", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "eyJfcmFpbHMi--1f2e", embed: true }), { editor: true })

  assert.match(mjml, /src="https:\/\/app\.example\.com\/rails\/active_storage\/blobs\/abc\/logo\.png"/)
  assert.doesNotMatch(mjml, /embed_image/)
})

test("an uploaded image that isn't embedded is linked", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "eyJfcmFpbHMi--1f2e" }))

  assert.match(mjml, /src="https:\/\/app\.example\.com\/rails\/active_storage\/blobs\/abc\/logo\.png"/)
})

test("the embed setting shows only for uploaded images", () => {
  const embed = getBlock("image").fields[0].fields.find((field) => field.key === "data.embed")
  const editor = { media: { enabled: true } }

  assert.equal(embed.visible(createNode("image", { data: { image: "abc" } }), editor), true)
  assert.equal(embed.visible(createNode("image", { attributes: { src: "https://example.com/a.png" } }), editor), false)
  assert.equal(embed.visible(createNode("image", { data: { image: "abc" } }), { media: { enabled: false } }), false)
})

test("the embed setting comes right after the image", () => {
  const keys = getBlock("image").fields[0].fields.map((field) => field.key)
  assert.equal(keys[keys.indexOf("attributes.src") + 1], "data.embed")
})
