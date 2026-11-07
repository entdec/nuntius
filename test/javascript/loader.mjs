// Node module loader that resolves bare specifiers the way the browser import
// map does: "nuntius/..." to app/javascript/nuntius, and "tess_edit/..." to the
// installed tess_edit gem (TESS_EDIT_PATH, set by `npm test`).
import { registerHooks } from "node:module"
import { pathToFileURL, fileURLToPath } from "node:url"
import path from "node:path"

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..")
const tessEdit = process.env.TESS_EDIT_PATH
if (!tessEdit) throw new Error("Set TESS_EDIT_PATH to the tess_edit gem, or run the tests with npm test")

const roots = {
  nuntius: path.join(root, "app/javascript/nuntius"),
  tess_edit: path.join(tessEdit, "app/javascript/tess_edit")
}

function resolve(specifier, context, next) {
  const [name, ...rest] = specifier.split("/")
  if (roots[name] && rest.length) return { url: pathToFileURL(path.join(roots[name], `${rest.join("/")}.js`)).href, shortCircuit: true }
  return next(specifier, context)
}

registerHooks({ resolve })
