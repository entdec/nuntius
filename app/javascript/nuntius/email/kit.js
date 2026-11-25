// The email kit: what Nuntius' email editor makes. The document becomes MJML
// in the browser (mjml.js), which the server compiles to HTML with MRML
// (Nuntius::Mjml, TessEdit's "mjml" compiler), for the canvas and the html
// output alike. Liquid stays in both, for rendering at send time.
//
// Its blocks are its root (Email), Wrapper, Hero, Social and Navbar, and
// TessEdit's own, which it takes in with their MJML (render.js).

import { registerBlock, registerKit } from "tess_edit/core/registry"
import { compile } from "tess_edit/export/compile"
import { toMjml } from "nuntius/email/mjml"
import { sampleEmail } from "nuntius/email/sample"
import { extendTessEditBlocks } from "nuntius/email/render"
import email from "nuntius/email/blocks/email"
import wrapper from "nuntius/email/blocks/wrapper"
import hero from "nuntius/email/blocks/hero"
import social from "nuntius/email/blocks/social"
import navbar from "nuntius/email/blocks/navbar"

const mjmlCompile = (mjml, { compileUrl, signal }) => compile(mjml, { compiler: "mjml", url: compileUrl, signal })

export const kit = registerKit({
  key: "email",
  name: "Email",
  root: "email",
  // What the root was called before
  aliases: ["page", "root"],
  starter: sampleEmail,
  devices: [
    { key: "desktop", icon: "desktop", title: "Desktop" },
    { key: "mobile", icon: "mobile", title: "Mobile", width: "375px" }
  ],
  // The Blocks panel's tiles: TessEdit's and the email's mixed, by category
  palette: ["section-1", "section-2", "section-3", "section-4", "section-1-2", "section-2-1", "column", "wrapper", "hero", "content", "text", "heading", "image", "button", "divider", "spacer", "social", "navbar", "raw", "loop", "condition", "assign", "table"],
  previewTitle: "Preview the email as sent, with Liquid tags",
  canvas: (doc, { editor, ...options }) => mjmlCompile(toMjml(doc, { editor }), options),
  async outputs(doc, options) {
    const mjml = toMjml(doc)
    const result = await mjmlCompile(mjml, options)
    if (!result) return null
    return { outputs: { mjml, html: result.html || "" }, errors: result.errors }
  },
  notes: { mjml: "Liquid loops and conditions are in <mj-raw> tags.", html: "Liquid is left in place for rendering at send time." },
  errors: "The email could not be compiled"
})

;[email, wrapper, hero, social, navbar].forEach(registerBlock)
extendTessEditBlocks()
