// The Nuntius blocks for the email editor, and the MJML they export.
import { test } from "node:test"
import assert from "node:assert/strict"
import { existsSync, readFileSync, writeFileSync } from "node:fs"
import { createDocument, createNode, insert, normalize } from "tess_edit/core/document"
import { createFromPalette } from "tess_edit/core/document"
import { registerBlock, registerCategory } from "tess_edit/core/registry"
import { toMjml } from "tess_edit/export/mjml"
import content, { CONTENT_END, CONTENT_START } from "nuntius/blocks/content"
import viewInBrowser from "nuntius/blocks/view_in_browser"
import subscription from "nuntius/blocks/subscription"

registerCategory({ key: "nuntius", label: "Nuntius", order: 25 })
;[content, viewInBrowser, subscription].forEach(registerBlock)

// A layout: a section, then a Content block holding a section with a column.
function layout() {
  const doc = createDocument()
  insert(doc, doc.id, 0, createFromPalette("section-1"))
  const box = insert(doc, doc.id, 1, createNode("content"))
  const section = insert(doc, box.id, 0, createFromPalette("section-1"))
  return { doc, box, column: section.children[0] }
}

test("the Content block marks its contents for Nuntius, outside the editor only", () => {
  const { doc, column } = layout()
  insert(doc, column.id, 0, createFromPalette("text"))

  const mjml = toMjml(doc)
  assert.equal(mjml.split(CONTENT_START).length, 2)
  assert.match(mjml, new RegExp(`${CONTENT_START.replace(/[/!]/g, "\\$&")}\\s*<mj-section[\\s\\S]*<mj-text[\\s\\S]*${CONTENT_END.replace(/[/!]/g, "\\$&")}`))
  assert.doesNotMatch(toMjml(doc, { editor: true }), /nuntius:content/)
})

test("the markers are the ones Nuntius::EmailDesign looks for", () => {
  assert.equal(CONTENT_START, "<mj-raw><!-- nuntius:content --></mj-raw>")
  assert.equal(CONTENT_END, "<mj-raw><!-- /nuntius:content --></mj-raw>")
})

test("an empty Content block shows a placeholder in the editor", () => {
  const doc = createDocument()
  const box = insert(doc, doc.id, 0, createNode("content"))
  assert.match(toMjml(doc, { editor: true }), new RegExp(`tessph-${box.id}`))
})

test("View in browser links to the message URL, kept away from Liquid", () => {
  const { doc, column } = layout()
  const block = insert(doc, column.id, 0, createNode("view_in_browser", { data: { before: "Trouble reading?", text: "" } }))

  const mjml = toMjml(doc)
  assert.match(mjml, /<mj-text align="center" padding="10px 25px" font-size="12px">Trouble reading\? <a href="\{% raw %\}\{\{message_url\}\}\{% endraw %\}" data-nuntius-tracking="false"[^>]*>View this email in your browser<\/a><\/mj-text>/)
  assert.match(toMjml(doc, { editor: true }), new RegExp(`css-class="tess-${block.id}"`))
})

test("Manage subscription shows only when there is a subscriber", () => {
  const { doc, column } = layout()
  insert(doc, column.id, 0, createNode("subscription", { data: { text: "Unsubscribe" } }))

  const mjml = toMjml(doc)
  assert.match(mjml, /<mj-raw>\{% if subscriber_url %\}<\/mj-raw>\s*<mj-text[^>]*><a href="\{\{ subscriber_url \}\}" data-nuntius-tracking="false"[^>]*>Unsubscribe<\/a><\/mj-text>\s*<mj-raw>\{% endif %\}<\/mj-raw>/)
  assert.doesNotMatch(toMjml(doc, { editor: true }), /\{% if/)
})

test("the link text is escaped and keeps Liquid", () => {
  const { doc, column } = layout()
  insert(doc, column.id, 0, createNode("subscription", { data: { before: "Not for you, {{ subscriber.first_name }}? <3", text: "Stop & go" } }))

  const mjml = toMjml(doc)
  assert.match(mjml, /Not for you, \{\{ subscriber\.first_name \}\}\? &lt;3 <a [^>]*>Stop &amp; go<\/a>/)
})

// A layout built from these blocks, kept in test/fixtures/files for the Ruby
// tests, which compile it, put a campaign's content into it and send it.
// After an intended change, regenerate it and review the diff:
//
//   UPDATE_SNAPSHOTS=1 npm test
test("the layout fixture for the Ruby tests is up to date", () => {
  const doc = createDocument()
  const header = insert(doc, doc.id, 0, createFromPalette("section-1"))
  insert(doc, header.children[0].id, 0, createNode("view_in_browser"))
  const box = insert(doc, doc.id, 1, createNode("content"))
  const body = insert(doc, box.id, 0, createFromPalette("section-1"))
  insert(doc, body.children[0].id, 0, createNode("text"))
  const footer = insert(doc, doc.id, 2, createFromPalette("section-1"))
  insert(doc, footer.children[0].id, 0, createNode("subscription", { data: { before: "Had enough?" } }))

  const file = new URL("../fixtures/files/nuntius_blocks_layout.mjml", import.meta.url)
  const mjml = toMjml(doc)
  if (process.env.UPDATE_SNAPSHOTS || !existsSync(file)) writeFileSync(file, mjml)
  assert.equal(mjml, readFileSync(file, "utf8"), "run UPDATE_SNAPSHOTS=1 npm test if the change is intended")
})

// The starting layouts Nuntius ships (config/nuntius/starting_layouts), as
// the editor exports them, for the Ruby tests that compile them.
for (const key of ["basic", "newsletter", "transactional", "empty"]) {
  test(`the ${key} starting layout has one Content block and its fixture is up to date`, () => {
    const doc = normalize(readFileSync(new URL(`../../config/nuntius/starting_layouts/${key}.json`, import.meta.url), "utf8"))
    const mjml = toMjml(doc)
    assert.equal(mjml.split(CONTENT_START).length, 2)

    const file = new URL(`../fixtures/files/starting_layouts/${key}.mjml`, import.meta.url)
    if (process.env.UPDATE_SNAPSHOTS || !existsSync(file)) writeFileSync(file, mjml)
    assert.equal(mjml, readFileSync(file, "utf8"), "run UPDATE_SNAPSHOTS=1 npm test if the change is intended")
  })
}
