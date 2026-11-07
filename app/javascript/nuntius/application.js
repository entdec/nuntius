// Entry point. The host app imports it after satis, whose Stimulus
// application (window.Stimulus) it registers the email editor with.

import { getBlock, blockTypes, registerBlock, registerCategory, registerTessEdit } from "tess_edit"
import { imageFields } from "tess_edit/core/media"
import content from "nuntius/blocks/content"
import viewInBrowser from "nuntius/blocks/view_in_browser"
import subscription from "nuntius/blocks/subscription"
import image from "nuntius/blocks/image"
import { withImageNames } from "nuntius/blocks/image_names"

registerCategory({ key: "mailing", label: "Mailing", order: 25 })
// image replaces TessEdit's own Image block
;[content, viewInBrowser, subscription, image].forEach(registerBlock)
// and the other blocks with images (backgrounds) refer to uploads by name
blockTypes()
  .map(getBlock)
  .filter((definition) => definition.type !== "image" && imageFields(definition).length)
  .forEach((definition) => registerBlock(withImageNames(definition)))

registerTessEdit(window.Stimulus)
