// How a section's or wrapper's background image fills it: MJML's
// background-size, background-repeat and background-position-x and -y, which
// it also gives Outlook's VML. Shown once the block has a background image.
//
// Without a size or repeat of its own a background image covers the block
// once, as a photo is meant to (withBackgroundDefaults): Original and Repeat
// tile it, MJML's own defaults.

const DEFAULTS = { "background-size": "cover", "background-repeat": "no-repeat" }

const hasImage = (node, editor) => editor?.kit?.key === "email" && !!(node.attributes?.["background-url"] || node.data?.background)

export const backgroundImage = {
  title: "Background image",
  before: "Border",
  fields: [
    {
      key: "attributes.background-size",
      label: "Size",
      type: "segmented",
      options: [
        { value: "auto", label: "Original" },
        { value: "cover", label: "Cover" },
        { value: "contain", label: "Contain" }
      ],
      hint: "Without a choice the image covers it, once.",
      visible: hasImage
    },
    {
      key: "attributes.background-repeat",
      label: "Repeat",
      type: "segmented",
      options: [
        { value: "repeat", label: "Repeat" },
        { value: "no-repeat", label: "Don't repeat" }
      ],
      visible: hasImage
    },
    {
      key: "attributes.background-position-x",
      label: "Horizontal",
      type: "segmented",
      options: [
        { value: "left", label: "Left" },
        { value: "center", label: "Center" },
        { value: "right", label: "Right" }
      ],
      visible: hasImage
    },
    {
      key: "attributes.background-position-y",
      label: "Vertical",
      type: "segmented",
      options: [
        { value: "top", label: "Top" },
        { value: "center", label: "Center" },
        { value: "bottom", label: "Bottom" }
      ],
      visible: hasImage
    }
  ]
}

// The node with its background image's defaults for what it doesn't set itself
export function withBackgroundDefaults(node) {
  const attributes = node.attributes || {}
  if (!attributes["background-url"]) return node

  const defaults = Object.fromEntries(Object.entries(DEFAULTS).filter(([name]) => !attributes[name]))
  return { ...node, attributes: { ...attributes, ...defaults } }
}
