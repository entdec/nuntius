// The email kit's MJML (nuntius/email): TessEdit's blocks and the email's own.
import { test } from "node:test"
import assert from "node:assert/strict"
import { createDocument, createFromPalette, createNode, insert, normalize, withContent, contentNode } from "tess_edit/core/document"
import { getBlock, getKit, kitOf, paletteItems } from "tess_edit/core/registry"
import { rows } from "tess_edit/core/table"
import "nuntius/email/kit"
import { toMjml } from "nuntius/email/mjml"
import { sampleEmail } from "nuntius/email/sample"

const paragraph = (text) => ({ type: "doc", content: [{ type: "paragraph", content: [{ type: "text", text }] }] })

function email() {
  const doc = createDocument("email")
  const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
  return { doc, column: section.children[0] }
}

test("the email is a kit of TessEdit's blocks and its own", () => {
  assert.equal(kitOf(createDocument("email")).key, "email")
  for (const type of ["section", "column", "text", "image", "button", "divider", "spacer", "raw", "loop", "condition", "assign", "content", "table", "table_row", "table_cell", "wrapper", "hero", "social", "navbar"]) {
    assert.ok(getBlock(type).kits.includes("email"), type)
    assert.equal(typeof getBlock(type).render.mjml, "function", type)
  }
})

test("its tiles are in the order they had in TessEdit", () => {
  assert.deepEqual(
    paletteItems("email").map((item) => item.key),
    ["section-1", "section-2", "section-3", "section-4", "section-1-2", "section-2-1", "column", "wrapper", "hero", "content", "text", "heading", "image", "button", "divider", "spacer", "social", "navbar", "raw", "loop", "condition", "assign", "table"]
  )
})

test("documents whose root was called page or root load as emails", () => {
  for (const type of ["page", "root"]) {
    const doc = normalize(JSON.stringify({ ...createDocument("email"), type }), { kit: "email" })
    assert.equal(doc.type, "email")
  }
})

test("the sample is an email, and the editor's starter", () => {
  assert.equal(getKit("email").starter, sampleEmail)
  assert.equal(sampleEmail().type, "email")
})

test("loops and conditions become Liquid in mj-raw", () => {
  const { doc, column } = email()
  const loop = insert(doc, column.id, 0, createNode("loop", { data: { variable: "line", collection: "order.lines" } }))
  insert(doc, loop.id, 0, createNode("text", { data: { content: paragraph("{{ line.name }}") } }))
  const condition = insert(doc, doc.id, 1, createNode("condition", { data: { expression: "order.total > 100" } }))
  insert(doc, condition.id, 0, createFromPalette("section-1"))

  const mjml = toMjml(doc)
  assert.match(mjml, /<mj-raw>\{% for line in order\.lines %\}<\/mj-raw>/)
  assert.match(mjml, /<mj-raw>\{% if order\.total > 100 %\}<\/mj-raw>/)
  assert.doesNotMatch(mjml, /tess-/)
})

test("editor MJML marks blocks and shows placeholders, without Liquid tags", () => {
  const doc = createDocument("email")
  const section = insert(doc, doc.id, 0, createFromPalette("section-2"))
  const loop = insert(doc, doc.id, 1, createNode("loop"))
  const mjml = toMjml(doc, { editor: true })
  assert.match(mjml, new RegExp(`css-class="tess-${section.id}"`))
  assert.match(mjml, new RegExp(`css-class="tessph-${section.children[0].id}"`))
  assert.match(mjml, new RegExp(`css-class="tessph-${loop.id}"`))
  assert.doesNotMatch(mjml, /\{%/)
})

test("editor MJML keeps a block's own css-class after its marker", () => {
  const doc = createDocument("email")
  const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
  section.attributes["css-class"] = "outer"
  assert.match(toMjml(doc, { editor: true }), new RegExp(`css-class="tess-${section.id} outer"`))
  assert.match(toMjml(doc), /css-class="outer"/)
})

test("an Assign is Liquid in mj-raw, nothing on the canvas", () => {
  const { doc, column } = email()
  insert(doc, column.id, 0, createNode("assign", { data: { variable: "lines", expression: 'order.lines | where: "kind", "product"' } }))
  assert.match(toMjml(doc), /<mj-raw>\{% assign lines = order\.lines \| where: "kind", "product" %\}<\/mj-raw>/)
  assert.doesNotMatch(toMjml(doc, { editor: true }), /assign/)
})

test("a table is an mj-table of HTML, its styles inline, its Loops' rows between Liquid tags", () => {
  const { doc, column } = email()
  const table = insert(doc, column.id, 0, createFromPalette("table"))
  const [, first, second] = rows(table)
  table.data.columns[2].width = "60px"
  table.data.stripe = "#f9fafb"
  const loop = insert(doc, table.id, 1, createNode("loop", { data: { variable: "line", collection: "order.lines" } }))
  table.children.splice(2, 1)
  insert(doc, loop.id, 0, first)
  first.children[0].children[0].data.content = paragraph("{{ line.name }}")
  first.children[2].children.push(createNode("image", { attributes: { src: "https://example.com/a.png" } }))
  second.data.lineAbove = "3px"
  second.children[0].data.colspan = "2"
  second.children.splice(1, 1)

  const mjml = toMjml(doc)
  assert.match(mjml, /<mj-table padding="10px 25px"><colgroup><col><col><col style="width:60px"><\/colgroup><thead><tr><th style="border:1px solid #d1d5db;padding:6px 8px;text-align:left;vertical-align:top;background-color:#f3f4f6;font-weight:bold">/)
  assert.match(mjml, /<tbody>\{% for line in order\.lines %\}\n\s*<tr><td style="[^"]*"><div style="padding:0px"><p[^>]*>\{\{ line\.name \}\}<\/p><\/div><\/td>/)
  assert.match(mjml, /<img src="https:\/\/example\.com\/a\.png" alt="" style="display:block;max-width:100%;height:auto;border:0"><\/div><\/td><\/tr>\n\s*\{% endfor %\}/)
  assert.match(mjml, /<td colspan="2" style="border:1px solid #d1d5db;border-top-width:3px;[^"]*background-color:#f9fafb">/)

  const editor = toMjml(doc, { editor: true })
  assert.doesNotMatch(editor, /\{%/)
  assert.match(editor, new RegExp(`<mj-table padding="10px 25px" css-class="tess-${table.id}">`))
  assert.match(editor, new RegExp(`<tr class="tess-${first.id}"><td class="tess-${first.children[0].id}"`))
})

test("a table's button in a cell is an HTML link", () => {
  const { doc, column } = email()
  const table = insert(doc, column.id, 0, createFromPalette("table"))
  rows(table)[1].children[0].children.push(createNode("button", { attributes: { href: "{{ order.url }}" }, data: { content: "Order" } }))
  assert.match(toMjml(doc), /<a href="\{\{ order\.url \}\}" style="display:inline-block;[^"]*">Order<\/a>/)
})

test("a layout's Content block keeps its markers in mj-raw", () => {
  const layout = createDocument("email")
  insert(layout, layout.id, 0, createFromPalette("section-1"))
  insert(layout, layout.id, 1, createNode("content", { children: [createFromPalette("section-1")] }))
  const doc = withContent(layout, [createFromPalette("section-2")])
  assert.equal(contentNode(doc).children[0].children.length, 2)
  assert.match(toMjml(doc), /<mj-raw><!-- tess-edit:content --><\/mj-raw>\n\s*<mj-section/)
})

test("a section can be full width, in an email only", () => {
  const field = getBlock("section").fields.flatMap((group) => group.fields).find((candidate) => candidate.key === "attributes.full-width")
  assert.equal(field.visible(null, { kit: { key: "email" } }), true)
  assert.equal(field.visible(null, { kit: { key: "pdf" } }), false)
})

test("a section's or wrapper's background image covers it once unless it says otherwise", () => {
  const { doc } = email()
  const section = doc.children[0]
  section.attributes = { "background-url": "https://example.com/bg.jpg" }
  assert.match(toMjml(doc), /<mj-section background-url="https:\/\/example.com\/bg.jpg" background-size="cover" background-repeat="no-repeat"/)

  section.attributes = { "background-url": "https://example.com/bg.jpg", "background-size": "auto", "background-repeat": "repeat", "background-position-x": "left", "background-position-y": "bottom" }
  assert.match(toMjml(doc), /<mj-section background-url="https:\/\/example.com\/bg.jpg" background-size="auto" background-repeat="repeat" background-position-x="left" background-position-y="bottom"/)

  section.attributes = { "background-color": "#ffffff" }
  assert.doesNotMatch(toMjml(doc), /background-size|background-repeat/)

  const wrapper = insert(doc, doc.id, 0, createFromPalette("wrapper"))
  wrapper.attributes = { "background-url": "https://example.com/bg.jpg", "background-size": "contain" }
  assert.match(toMjml(doc), /<mj-wrapper background-url="https:\/\/example.com\/bg.jpg" background-size="contain" background-repeat="no-repeat"/)
})

test("a section's and wrapper's Background image group shows once there's an image, before Border", () => {
  const editor = { kit: { key: "email" } }
  for (const type of ["section", "wrapper"]) {
    const groups = getBlock(type).fields
    const titles = groups.map((group) => group.title)
    assert.equal(titles.indexOf("Background image") + 1, titles.indexOf("Border"), type)

    const fields = groups.find((group) => group.title === "Background image").fields
    assert.deepEqual(fields.map((field) => field.key), ["attributes.background-size", "attributes.background-repeat", "attributes.background-position-x", "attributes.background-position-y"])
    const shown = (node) => fields.filter((field) => field.visible(node, editor)).length
    assert.equal(shown({ attributes: {} }), 0, type)
    assert.equal(shown({ attributes: { "background-url": "https://example.com/bg.jpg" } }), 4, type)
    assert.equal(shown({ attributes: {}, data: { background: "bg.jpg" } }), 4, type)
  }
})
