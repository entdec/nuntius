// Entry point. The host app imports it after satis, whose Stimulus
// application (window.Stimulus) it registers the email editor with.

import { registerBlock, registerCategory, registerTessEdit } from "tess_edit"
import content from "nuntius/blocks/content"
import viewInBrowser from "nuntius/blocks/view_in_browser"
import subscription from "nuntius/blocks/subscription"
import image from "nuntius/blocks/image"

registerCategory({ key: "mailing", label: "Mailing", order: 25 })
// image replaces TessEdit's own Image block
;[content, viewInBrowser, subscription, image].forEach(registerBlock)

registerTessEdit(window.Stimulus)
