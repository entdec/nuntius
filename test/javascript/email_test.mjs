// A template's own settings in the email's root Inspect (nuntius/blocks/email.js).
import { test } from "node:test"
import assert from "node:assert/strict"
import { getBlock } from "tess_edit/core/registry"
import "nuntius/blocks/email"

test("the root has a template's trigger, recipient and tracking, and a layout's details, around TessEdit's groups", () => {
  const groups = getBlock("email").fields
  assert.deepEqual(groups.map((group) => group.title), ["When", "Recipient", "Details", "Message", "Tracking", "Layout", "Theme", "Custom CSS"])
  assert.deepEqual(groups.find((group) => group.title === "Details").fields.map((field) => field.slot), ["name", "description"])
  assert.deepEqual(groups.find((group) => group.title === "When").fields.map((field) => [field.type, field.slot]), [["slot", "trigger"]])
  assert.equal(groups.find((group) => group.title === "Layout").fields.at(-1).slot, "layout")
})

test("From, To and the tracking show in a template's editor only", () => {
  const fields = getBlock("email").fields.flatMap((group) => group.fields).filter((field) => ["data.from", "data.to", "data.linkTracking", "data.openTracking"].includes(field.key))
  assert.equal(fields.length, 4)
  assert.ok(fields.every((field) => field.visible(null, { options: { template: true } })))
  assert.ok(fields.every((field) => !field.visible(null, { options: {} })))
})
