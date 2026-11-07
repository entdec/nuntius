// Nuntius' Image block: TessEdit's, with the option to embed an uploaded image.
import { test } from "node:test"
import assert from "node:assert/strict"
import { createDocument, createNode, find, insert } from "tess_edit/core/document"
import { createFromPalette } from "tess_edit/core/document"
import { getBlock, registerBlock } from "tess_edit/core/registry"
import { toMjml } from "tess_edit/export/mjml"
import image from "nuntius/blocks/image"
import { withImageNames } from "nuntius/blocks/image_names"

registerBlock(image)
;["hero", "section"].forEach((type) => registerBlock(withImageNames(getBlock(type))))

function emailWith(data) {
  const doc = createDocument()
  const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
  insert(doc, section.children[0].id, 0, createNode("image", { attributes: { src: "https://app.example.com/rails/active_storage/blobs/abc/logo.png" }, data }))
  return doc
}

test("an embedded image is sent with the email through embed_image, by its name", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "logo.png", embed: true }))

  assert.match(mjml, /<mj-image[^>]* src="\{\{ 'logo\.png' \| embed_image \}\}"/)
})

test("the editor's canvas shows an uploaded image from its URL", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "logo.png", embed: true }), { editor: true })

  assert.match(mjml, /src="https:\/\/app\.example\.com\/rails\/active_storage\/blobs\/abc\/logo\.png"/)
  assert.doesNotMatch(mjml, /embed_image|image_url/)
})

test("an uploaded image that isn't embedded is linked through image_url, by its name", () => {
  const mjml = toMjml(emailWith({ source: "upload", image: "logo.png" }))

  assert.match(mjml, /<mj-image[^>]* src="\{\{ 'logo\.png' \| image_url \}\}"/)
  assert.doesNotMatch(mjml, /active_storage/)
})

test("a web image keeps its URL", () => {
  const mjml = toMjml(emailWith({ source: "web", image: "logo.png" }))

  assert.match(mjml, /src="https:\/\/app\.example\.com\/rails\/active_storage\/blobs\/abc\/logo\.png"/)
})

test("an uploaded background is linked through image_url, by its name", () => {
  const doc = createDocument()
  const background = { attributes: { "background-url": "https://app.example.com/rails/active_storage/blobs/abc/sky.png" }, data: { background: "sky.png", backgroundSource: "upload" } }
  insert(doc, doc.id, 0, createNode("hero", background))
  insert(doc, doc.id, 1, createFromPalette("section-1"))
  Object.assign(find(doc, doc.children[1].id).node, background)

  const mjml = toMjml(doc)
  assert.match(mjml, /<mj-hero[^>]* background-url="\{\{ 'sky\.png' \| image_url \}\}"/)
  assert.match(mjml, /<mj-section[^>]* background-url="\{\{ 'sky\.png' \| image_url \}\}"/)
  assert.match(toMjml(doc, { editor: true }), /background-url="https:\/\/app\.example\.com/)
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
