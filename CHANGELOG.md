# Changelog

## 2.0.0 (unreleased)

Mail is now designed in an email editor ([TessEdit](https://github.com/tdegrunt/tess_edit), a new dependency from RubyGems) instead of written in Markdown or Trix. See [Email designs](README.md#email-designs) in the README.

### Added

- Layouts designed in the email editor, with one Content block where each template or campaign puts its own content. Templates and draft campaigns follow their layout when it changes, and show it locked in their editor.
- Starting layouts for new layouts: Basic, Newsletter, Transactional and Empty.
- Nuntius blocks in the editor: Content, View in browser and Manage subscription.
- Images uploaded in the editor, by button or by dragging a file onto the canvas, for Image blocks and the backgrounds of heroes, sections and wrappers. They're stored on the layout, template or campaign, and an Image block's image can be embedded in the email.
- The `embed_image` Liquid filter, which attaches an image to the email and returns a `cid:` reference.
- Converting a template with an old layout to the email editor, from its page in the admin.
- Lettermint webhooks: Nuntius creates and checks the webhook itself and updates messages from Lettermint's events (see [Lettermint](README.md#lettermint)).
- The `soft_bounced` message state, for temporary delivery failures the provider retries.

### Changed

- Every new mail and LMTP template and campaign needs a layout.
- Mail campaigns to a list that allows unsubscribing must contain the Manage subscription block.
- Templates and campaigns have a preview text.
- The editor compiles MJML on the server, at `<where Nuntius is mounted>/tess_edit/compile`, behind Nuntius' admin authentication.

### Removed

- Markdown and Trix editing of mail templates and campaigns. Templates with an old layout keep sending as before until you convert them.
- The `{{ subscriber_link }}` variable and the `subscriber_url_text` translation; use the Manage subscription block. `Subscriber#link` is replaced by `Subscriber#url(message)`.

### Upgrading from 1.x

1. **Send or delete draft campaigns first.** The migration refuses to run while campaigns are in draft or sending. Sent campaigns keep the HTML they were sent with.
2. **Install libvips** on the servers that run the admin. Nuntius now depends on image_processing for previews of images on the Media tabs, which needs it: e.g. `apt-get install libvips` or `brew install vips`. Active Storage has to be set up as well, as it was for layout attachments.
3. **Use Propshaft, importmap-rails and Tailwind CSS 4** (tailwindcss-rails 4.3 or later). Import Nuntius' JavaScript after Satis in `app/javascript/application.js`:

   ```js
   import "satis"
   import "nuntius"
   ```

   and add the styles to `app/assets/tailwind/application.css`:

   ```css
   @import "../builds/tailwind/nuntius";
   @import "../builds/tailwind/tess_edit";
   ```

4. **Run the migrations:**

   ```sh
   bin/rails nuntius:install:migrations
   bin/rails db:migrate
   ```

   The existing layouts become old layouts (`nuntius_old_layouts`, with their attachments), and templates and campaigns keep them as `old_layout_id`. New layouts go in `nuntius_layouts`. The migrations also add inline attachments (for `embed_image`), `converted_from` on templates and `nuntius_webhooks` (for Lettermint).
5. **Make new layouts and convert your templates.** Create layouts in the admin, then convert each template with an old layout from its page. Until then it keeps sending with its old layout.

   Translation keys of a template start with its layout's name. A template converted into a layout with another name gets new keys, so give the new layout the old one's name when you rely on them.
6. **Replace `{{ subscriber_link }}`** in your own templates with the Manage subscription block, or with a link to `{{ subscriber_url }}`.
