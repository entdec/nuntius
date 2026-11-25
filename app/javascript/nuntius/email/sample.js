// A sample email, for an editor that starts with one (data-tess-edit-sample-value)
// and for the tests.

import { createDocument, createNode } from "tess_edit/core/document"

const paragraph = (...content) => ({ type: "paragraph", content })
const text = (value, marks) => (marks ? { type: "text", text: value, marks } : { type: "text", text: value })
const doc = (...content) => ({ type: "doc", content })

const section = (attributes, ...columns) => createNode("section", { attributes, children: columns })
const column = (attributes, ...children) => createNode("column", { attributes, children })

export function sampleEmail() {
  const page = createDocument("email")
  page.data.subject = "Your order {{ order.number }}"
  page.data.preheader = "Thanks for shopping with us, {{ customer.first_name }}."

  page.children = [
    section(
      { padding: "24px 0px 8px" },
      column(
        {},
        createNode("text", {
          attributes: { align: "center", "font-size": "20px", "font-weight": "700", "letter-spacing": "1px" },
          data: { content: doc(paragraph(text("ACME STORE"))) }
        })
      )
    ),
    section(
      { "background-color": "#ffffff", padding: "32px 0px", "border-radius": "8px" },
      column(
        {},
        createNode("text", {
          attributes: { "font-size": "26px", "font-weight": "700", "line-height": "1.3" },
          data: { content: doc(paragraph(text("Thanks for your order, {{ customer.first_name }}!"))) }
        }),
        createNode("text", {
          data: {
            content: doc(
              paragraph(text("We've received order "), text("{{ order.number }}", [{ type: "bold" }]), text(" and will let you know when it ships.")),
              paragraph(),
              paragraph(text("Here's what you ordered:"))
            )
          }
        }),
        createNode("loop", {
          data: { variable: "line", collection: "order.lines" },
          children: [
            createNode("text", {
              attributes: { padding: "4px 25px" },
              data: { content: doc(paragraph(text("{{ line.quantity }} × {{ line.name }} — {{ line.total | money }}"))) }
            })
          ]
        }),
        createNode("divider", { attributes: { padding: "16px 25px" } }),
        createNode("button", { attributes: { href: "{{ order.url }}" }, data: { content: "View your order" } })
      )
    ),
    createNode("condition", {
      data: { expression: "customer.orders_count == 1" },
      children: [
        section(
          { padding: "24px 0px 0px" },
          column(
            { width: "50%" },
            createNode("image", { attributes: { src: "https://placehold.co/600x400/dbeafe/1e3a8a.png?text=Welcome", padding: "0px 12px 0px 25px", "border-radius": "6px" } })
          ),
          column(
            { width: "50%", "vertical-align": "middle" },
            createNode("text", {
              data: { content: doc(paragraph(text("Welcome!", [{ type: "bold" }])), paragraph(text("This is your first order. Here's 10% off the next one with code WELCOME10."))) }
            })
          )
        )
      ]
    }),
    section(
      { padding: "24px 0px" },
      column(
        {},
        createNode("social"),
        createNode("text", {
          attributes: { align: "center", "font-size": "12px", color: "#6b7280" },
          data: { content: doc(paragraph(text("ACME Store · Main Street 1 · Amsterdam")), paragraph(text("Unsubscribe", [{ type: "link", attrs: { href: "{{ unsubscribe_url }}" } }]))) }
        })
      )
    )
  ]
  return page
}
