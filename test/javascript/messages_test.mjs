// The editors of SMS, Push, Teams, Slack and Voice messages (nuntius/kits/messages.js).
import { test } from "node:test"
import assert from "node:assert/strict"
import { getBlock, getKit } from "tess_edit/core/registry"
import { createDocument } from "tess_edit/core/document"
import { smsLength } from "nuntius/kits/messages"

test("an SMS is 160 GSM characters, or 70 with Unicode, and longer ones go in parts", () => {
  assert.deepEqual(smsLength(""), { length: 0, single: 160, parts: 0, unicode: false })
  assert.deepEqual(smsLength("a".repeat(160)), { length: 160, single: 160, parts: 1, unicode: false })
  assert.equal(smsLength("a".repeat(161)).parts, 2)
  assert.equal(smsLength("a".repeat(307)).parts, 3)
  // € counts double in the GSM alphabet
  assert.equal(smsLength("€5").length, 3)
  assert.deepEqual(smsLength("Hi 👋"), { length: 5, single: 70, parts: 1, unicode: true })
  assert.equal(smsLength("ł".repeat(71)).parts, 2)
})

test("each transport is a kit of its root alone, with When, Recipient and its Message", () => {
  const messages = { sms: ["data.text"], push: ["data.text", "data.payload"], teams: ["data.text", "data.payload"], slack: ["data.text", "data.payload"], voice: ["data.text"] }
  for (const [key, fields] of Object.entries(messages)) {
    const kit = getKit(key)
    assert.equal(kit.blocks, false)
    assert.equal(kit.root, key)
    assert.equal(createDocument(key).type, key)
    const groups = getBlock(key).fields
    assert.deepEqual(groups.map((group) => group.title), ["When", "Recipient", "Message"])
    assert.deepEqual(groups[2].fields.map((field) => field.key), fields)
  }
  assert.match(getBlock("sms").fields[2].fields[0].hint("Hi"), /^2 \/ 160 · 1 SMS/)
})

test("without a preview URL the canvas shows the message as typed", async () => {
  const doc = createDocument("voice")
  doc.data.text = "<Response><Say>Hi</Say></Response>\n\n---\npath: /next\n---\n<Response><Hangup/></Response>"
  const { html, errors } = await getKit("voice").canvas(doc, { options: {} })
  assert.deepEqual(errors, [])
  assert.match(html, /Path \//)
  assert.match(html, /Path \/next/)
  assert.doesNotMatch(html, /path: \/next/)
})
