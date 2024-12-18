import { application } from "nuntius/controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

eagerLoadControllersFrom("nuntius/controllers", application)
