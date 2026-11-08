import { Controller } from "@hotwired/stimulus"

// The Translations tab: saves a text when it changes (or on Enter, which
// would otherwise submit the form around it) through the translations
// endpoint, Admin::TranslationsController, and says where it's kept.
export default class extends Controller {
  static targets = ["input", "status"]
  static values = { url: String }

  async save(event) {
    const input = event.target
    if (input.dataset.saved === input.value) return
    const status = input.parentElement.querySelector("[data-nuntius--translations-target='status']")
    const token = document.querySelector("meta[name='csrf-token']")?.content
    status.textContent = "…"
    status.className = "mt-1 text-xs text-gray-400"
    try {
      const response = await fetch(this.urlValue, {
        method: "PATCH",
        headers: { "Content-Type": "application/json", Accept: "application/json", ...(token ? { "X-CSRF-Token": token } : {}) },
        body: JSON.stringify({ key: input.dataset.key, locale: input.dataset.locale, value: input.value }),
        credentials: "same-origin"
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.errors?.join(", ") || response.statusText)
      const text = result.translation?.[input.dataset.locale]
      input.dataset.saved = input.value
      input.classList.toggle("border-red-300", !text)
      input.classList.toggle("dark:border-red-700", !text)
      input.classList.toggle("border-gray-300", Boolean(text))
      input.classList.toggle("dark:border-gray-600", Boolean(text))
      status.replaceChildren(text?.url ? Object.assign(document.createElement("a"), { href: text.url, target: "_blank", rel: "noopener", className: "hover:underline", textContent: text.source }) : text?.source || "")
      status.className = "mt-1 text-xs text-green-700"
    } catch (error) {
      status.textContent = error.message
      status.className = "mt-1 text-xs text-red-600"
    }
  }
}
