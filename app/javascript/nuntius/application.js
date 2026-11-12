// Entry point. The host app imports it after satis, whose Stimulus
// application (window.Stimulus) it registers the email editor and the view
// components (entdec-view_components) with.

import { getBlock, blockTypes, registerBlock, registerCategory, registerTessEdit } from "tess_edit"
import { imageFields } from "tess_edit/core/media"
import content from "nuntius/blocks/content"
import viewInBrowser from "nuntius/blocks/view_in_browser"
import subscription from "nuntius/blocks/subscription"
import image from "nuntius/blocks/image"
import "nuntius/blocks/email"
import { withImageNames } from "nuntius/blocks/image_names"
import ChainedSelectController from "nuntius/controllers/chained_select_controller"
import VariablesController from "nuntius/controllers/variables_controller"
import DescriptionController from "nuntius/controllers/description_controller"
import TranslationsController from "nuntius/controllers/translations_controller"
import { registerViewComponents } from "entdec/view_components"

registerCategory({ key: "mailing", label: "Mailing", order: 25 })
// image replaces TessEdit's own Image block
;[content, viewInBrowser, subscription, image].forEach(registerBlock)
// and the other blocks with images (backgrounds) refer to uploads by name
blockTypes()
  .map(getBlock)
  .filter((definition) => definition.type !== "image" && imageFields(definition).length)
  .forEach((definition) => registerBlock(withImageNames(definition)))

registerTessEdit(window.Stimulus)
registerViewComponents(window.Stimulus)
window.Stimulus.register("nuntius--chained-select", ChainedSelectController)
window.Stimulus.register("nuntius--variables", VariablesController)
window.Stimulus.register("nuntius--description", DescriptionController)
window.Stimulus.register("nuntius--translations", TranslationsController)
