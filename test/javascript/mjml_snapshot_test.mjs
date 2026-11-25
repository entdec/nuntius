// Snapshot tests: the MJML each of the email kit's tiles exports, compared to
// files in test/javascript/snapshots. The Rails tests compile them with MRML
// (test/lib/nuntius/mjml_test.rb) and render the sample with Liquid.
//
// After an intended change in output, regenerate and review the diff:
//
//   UPDATE_SNAPSHOTS=1 npm test

import { test } from "node:test"
import assert from "node:assert/strict"
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs"
import path from "node:path"
import { fileURLToPath } from "node:url"
import { createDocument, createFromPalette, insert, walk } from "tess_edit/core/document"
import { paletteItems } from "tess_edit/core/registry"
import "nuntius/email/kit"
import { toMjml } from "nuntius/email/mjml"
import { sampleEmail } from "nuntius/email/sample"

const here = path.dirname(fileURLToPath(import.meta.url))
const snapshots = path.join(here, "snapshots")
const update = !!process.env.UPDATE_SNAPSHOTS

function matchFile(file, actual) {
  if (update || !existsSync(file)) {
    mkdirSync(path.dirname(file), { recursive: true })
    writeFileSync(file, actual)
    return
  }
  assert.equal(actual, readFileSync(file, "utf8"), `${path.relative(process.cwd(), file)} changed; run UPDATE_SNAPSHOTS=1 npm test if that is intended`)
}

// Ids are random; number them so editor output is stable.
function stableIds(doc) {
  let n = 0
  walk(doc, (node) => {
    node.id = `b${++n}`
  })
  return doc
}

// An email with the tile where it belongs: layout tiles in the email,
// content tiles in a one-column section.
function documentWith(key) {
  const doc = createDocument("email")
  const item = createFromPalette(key)
  if (item.type === "column") {
    const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
    insert(doc, section.id, 1, item)
  } else if (["section", "wrapper", "hero"].includes(item.type)) {
    insert(doc, doc.id, 0, item)
  } else {
    const section = insert(doc, doc.id, 0, createFromPalette("section-1"))
    insert(doc, section.children[0].id, 0, item)
  }
  return stableIds(doc)
}

for (const item of paletteItems("email")) {
  test(`MJML for ${item.label}`, () => {
    const doc = documentWith(item.key)
    matchFile(path.join(snapshots, `${item.key}.mjml`), toMjml(doc))
    matchFile(path.join(snapshots, "editor", `${item.key}.mjml`), toMjml(doc, { editor: true }))
  })
}

test("MJML for the sample", () => {
  matchFile(path.join(snapshots, "sample.mjml"), toMjml(stableIds(sampleEmail())))
})
