// The editors of a template's or campaign's messages for SMS, Push, Teams,
// Slack and Voice: a TessEdit kit for each transport, of its root alone
// (blocks: false). Its Inspect has the email's When, Audience and Recipient
// groups (blocks/email.js) and a Message group of its own; the canvas
// previews the message, rendered by Nuntius with sample values
// (TemplatesController#preview, at the editor's previewUrl option), for a
// template's class chosen in the form. The template or campaign takes the
// root's data (Concerns::EmailDesigned#assign_message_design).

import { registerBlock, registerKit } from "tess_edit/core/registry"
import { createDocument } from "tess_edit/core/document"
import { highlightHtml } from "tess_edit/ui/code_input"
import { audience, recipient, when } from "nuntius/blocks/email"

const escape = (text) => String(text ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;")

// --- SMS length -------------------------------------------------------------------

const GSM = "@£$¥èéùìòÇ\nØø\rÅåΔ_ΦΓΛΩΠΨΣΘΞÆæßÉ !\"#¤%&'()*+,-./0123456789:;<=>?¡ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÑÜ§¿abcdefghijklmnopqrstuvwxyzäöñüà"
const GSM_EXTENDED = "^{}\\[~]|€"

// How long a text is as an SMS, and in how many parts it's sent: 160
// characters (153 a part) in the GSM alphabet, where some count double, or
// 70 (67 a part) with any other character (Unicode)
export function smsLength(text) {
  const characters = [...String(text ?? "")]
  const unicode = !characters.every((character) => GSM.includes(character) || GSM_EXTENDED.includes(character))
  const length = unicode ? String(text ?? "").length : characters.reduce((sum, character) => sum + (GSM_EXTENDED.includes(character) ? 2 : 1), 0)
  const [single, part] = unicode ? [70, 67] : [160, 153]
  const parts = length === 0 ? 0 : length <= single ? 1 : Math.ceil(length / part)
  return { length, single, parts, unicode }
}

const smsSummary = (text) => {
  const { length, single, parts, unicode } = smsLength(text)
  return `${length} / ${single} · ${parts} SMS${unicode ? " · Unicode" : ""}`
}

// --- the preview ----------------------------------------------------------------------

// The message rendered with sample values: { text, payload, errors }, null when aborted
async function render(doc, { signal, options, element }) {
  const form = element?.closest("form")
  const body = new FormData()
  body.append("template[transport]", doc.type)
  body.append("template[klass]", form?.elements.namedItem("template[klass]")?.value || "")
  body.append("template[text]", doc.data.text || "")
  body.append("template[payload]", doc.data.payload || "")
  try {
    const response = await fetch(options.previewUrl, {
      method: "POST",
      body,
      signal,
      credentials: "same-origin",
      headers: { Accept: "application/json", "X-CSRF-Token": document.querySelector("meta[name=csrf-token]")?.content || "" }
    })
    if (!response.ok) return { text: "", payload: null, errors: [`${response.status} ${response.statusText}`] }
    return await response.json()
  } catch (error) {
    if (error.name === "AbortError") return null
    return { text: "", payload: null, errors: [error.message] }
  }
}

const CSS = `
  * { box-sizing: border-box }
  body { margin: 0; min-height: 100vh; padding: 40px 24px; font: 14px/1.45 system-ui, -apple-system, "Segoe UI", sans-serif; color: #111827; background: #f3f4f6 }
  .phone { width: 320px; margin: 0 auto; padding: 12px; border-radius: 44px; background: #111827; box-shadow: 0 10px 30px rgb(0 0 0 / .2) }
  .screen { min-height: 520px; border-radius: 34px; overflow: hidden; background: #fff }
  .bar { display: flex; justify-content: space-between; padding: 14px 26px 6px; font-size: 13px; font-weight: 600 }
  .sender { padding: 6px 16px 10px; border-bottom: 1px solid #e5e7eb; text-align: center; font-size: 12px; color: #6b7280 }
  .bubble { max-width: 80%; margin: 14px; padding: 9px 13px; border-radius: 18px 18px 18px 4px; background: #e5e7eb; white-space: pre-wrap; overflow-wrap: anywhere }
  .lock { min-height: 520px; padding: 18px 14px; background: linear-gradient(160deg, #1e3a8a, #6d28d9 60%, #db2777); color: #fff }
  .clock { margin: 26px 0 4px; text-align: center; font-size: 64px; font-weight: 300; line-height: 1 }
  .date { margin-bottom: 30px; text-align: center; font-size: 15px; opacity: .85 }
  .notification { padding: 12px 14px; border-radius: 18px; background: rgb(255 255 255 / .85); color: #111827; white-space: pre-wrap; overflow-wrap: anywhere }
  .notification header { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; font-size: 12px; color: #4b5563; text-transform: uppercase; letter-spacing: .03em }
  .notification header span:last-child { margin-left: auto; text-transform: none }
  .icon { width: 20px; height: 20px; border-radius: 5px; background: #4f46e5 }
  .panel { max-width: 640px; margin: 0 auto }
  .message { display: flex; gap: 10px; padding: 14px 16px; border-radius: 8px; background: #fff; box-shadow: 0 1px 2px rgb(0 0 0 / .08) }
  .avatar { flex: none; width: 36px; height: 36px; border-radius: 6px; background: #4f46e5 }
  .message strong { display: block }
  .text { white-space: pre-wrap; overflow-wrap: anywhere }
  h2 { margin: 22px 0 8px; font-size: 12px; font-weight: 600; text-transform: uppercase; letter-spacing: .04em; color: #6b7280 }
  pre { margin: 0; padding: 12px 14px; border: 1px solid #e5e7eb; border-radius: 8px; background: #fff; font: 12px/1.6 ui-monospace, SFMono-Regular, Menlo, monospace; white-space: pre-wrap; overflow-wrap: anywhere }
  .note { margin: 10px auto 0; text-align: center; font-size: 12px; color: #6b7280 }
  a.open { display: inline-block; margin-top: 10px; color: #2563eb; font-size: 13px; text-decoration: none }
  a.open:hover { text-decoration: underline }
  .empty { color: #9ca3af; font-style: italic }
  .text-purple-700 { color: #7e22ce } .text-blue-700 { color: #1d4ed8 } .text-amber-700 { color: #b45309 } .text-green-700 { color: #15803d } .text-gray-400 { color: #9ca3af; font-style: italic }
`

const page = (doc, body) => `<!doctype html><html><head><meta charset="utf-8"><style>${CSS}</style></head><body class="tess-${doc.id}">${body}</body></html>`

const text = (value, empty) => (String(value ?? "").trim() ? escape(value) : `<span class="empty">${escape(empty)}</span>`)
const json = (payload) => escape(JSON.stringify(payload, null, 2))
const sender = (doc) => escape(doc.data.from || "Sender")

const PREVIEWS = {
  // Counted without the ‹ › around the samples, which aren't GSM characters
  sms: (doc, { text: message }) => `
    <div class="phone"><div class="screen">
      <div class="bar"><span>9:41</span><span>●●●</span></div>
      <div class="sender">${sender(doc)}</div>
      <div class="bubble">${text(message, "No text yet")}</div>
    </div></div>
    <p class="note">With sample values: ${escape(smsSummary(String(message ?? "").replace(/[‹›]/g, "")))}</p>`,

  push: (doc, { text: message, payload }) => `
    <div class="phone"><div class="lock">
      <div class="clock">9:41</div>
      <div class="date">Monday 9 June</div>
      <div class="notification"><header><span class="icon"></span><span>App</span><span>now</span></header>${text(message, "No text yet")}</div>
    </div></div>
    ${payload ? `<div class="panel"><h2>Data</h2><pre>${json(payload)}</pre></div>` : ""}`,

  teams: (doc, { text: message, payload }) => `
    <div class="panel">
      <div class="message"><span class="avatar"></span><div><strong>${sender(doc)}</strong><div class="text">${text(message, "No text yet")}</div></div></div>
      ${payload ? `<h2>Card</h2><pre>${json(payload)}</pre>` : ""}
      <a class="open" data-tess-open href="https://adaptivecards.io/designer/">Open the Adaptive Cards Designer ↗</a>
    </div>`,

  slack: (doc, { text: message, payload }) => {
    const blocks = payload?.blocks ? { blocks: payload.blocks } : payload
    const builder = `https://app.slack.com/block-kit-builder#${encodeURIComponent(JSON.stringify(blocks || { blocks: [] }))}`
    return `
    <div class="panel">
      <div class="message"><span class="avatar"></span><div><strong>${sender(doc)}</strong><div class="text">${text(message, "No text yet")}</div></div></div>
      ${payload ? `<h2>Blocks</h2><pre>${json(payload)}</pre>` : ""}
      <a class="open" data-tess-open href="${escape(builder)}">Open in Block Kit Builder ↗</a>
    </div>`
  },

  // Each part, apart from the next by a blank line, answers a path of the
  // call (TwilioVoiceProvider), "/" unless its front matter says otherwise
  voice: (doc, { text: script }) => {
    const parts = String(script || "").replace(/\r/g, "").split("\n\n").filter((part) => part.trim())
    if (!parts.length) return `<div class="panel"><pre><span class="empty">No TwiML yet</span></pre></div>`
    return `<div class="panel">${parts
      .map((part) => {
        const front = part.match(/^---\n([\s\S]*?)\n---\n?/)
        const path = front?.[1].match(/^path:\s*(.+)$/m)?.[1].trim() || "/"
        return `<h2>Path ${escape(path)}</h2><pre>${highlightHtml(front ? part.slice(front[0].length) : part)}</pre>`
      })
      .join("")}</div>`
  }
}

// --- the kits --------------------------------------------------------------------------

const MESSAGE = {
  sms: [{ key: "data.text", label: "Text", type: "textarea", liquid: true, hint: (value) => `${smsSummary(value)}, as typed` }],
  push: [
    { key: "data.text", label: "Text", type: "textarea", liquid: true },
    { key: "data.payload", label: "Payload", type: "code", language: "yaml", hint: "YAML, sent with the notification as its data." }
  ],
  teams: [
    { key: "data.text", label: "Text", type: "textarea", liquid: true },
    { key: "data.payload", label: "Card", type: "code", language: "yaml", hint: "YAML: the message's Adaptive Card." }
  ],
  slack: [
    { key: "data.text", label: "Text", type: "textarea", liquid: true, hint: "Shown in notifications, and when there are no blocks." },
    { key: "data.payload", label: "Blocks", type: "code", language: "yaml", hint: "YAML: blocks: and anything else Slack takes with the message." }
  ],
  voice: [{ key: "data.text", label: "TwiML", type: "code", language: "xml", hint: "A blank line starts the part for another path, which names it between --- lines (path: /next). {{url}} is the call's next step." }]
}

const NAMES = { sms: "SMS", push: "Push", teams: "Teams", slack: "Slack", voice: "Voice" }

for (const [key, name] of Object.entries(NAMES)) {
  registerKit({
    key,
    name,
    root: key,
    blocks: false,
    starter: () => createDocument(key),
    previewTitle: "Preview the message",
    async canvas(doc, context) {
      if (!context.options?.previewUrl) return { html: page(doc, PREVIEWS[key](doc, { text: doc.data.text, payload: null })), errors: [] }
      const result = await render(doc, context)
      if (!result) return null
      return { html: page(doc, PREVIEWS[key](doc, result)), errors: result.errors || [] }
    },
    outputs: async () => ({ outputs: {}, errors: [] }),
    errors: "The preview could not be rendered"
  })

  registerBlock({
    type: key,
    name,
    icon: "root",
    kits: [key],
    defaults: () => ({ data: { text: "", ...(MESSAGE[key].some((field) => field.key === "data.payload") ? { payload: "" } : {}) } }),
    fields: [when(), audience(), recipient(), { title: "Message", fields: MESSAGE[key] }],
    render: { [key]: () => "" }
  })
}
