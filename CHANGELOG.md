# Changelog

## 2.0.0 (unreleased)

Mail is now designed in an email editor ([TessEdit](https://github.com/tdegrunt/tess_edit), a new dependency from RubyGems) instead of written in Markdown or Trix. See [Email designs](README.md#email-designs) in the README.

Every template, campaign, list, layout, locale and message now belongs to an account, through an `account_id` column instead of an `account_id` in its metadata, and templates can be global. See [Accounts](README.md#accounts) in the README.

### Added

- A message for each addressee, rendered with the addressee as `to`: a template's To can be drops, like `{{ order.contacts }}`, sent to their email or phone number (see [Addressees](README.md#addressees)). `Template#new_messages` gives them.
- The forms use view components from [entdec-view_components](https://github.com/entdec/view_components), a new dependency from GitHub (add `gem "entdec-view_components", github: "entdec/view_components"` to your Gemfile, and `@import "../builds/tailwind/entdec_view_components";` to your Tailwind CSS): pill selects, a variable picker, conditions, Liquid fields and a code editor (CodeMirror 6, replacing Satis's editor in Nuntius's forms).
- Liquid fields: a template's From, To and its text for SMS, push and Teams (now a plain text field), its code fields (Voice's TwiML, now with Liquid highlighted, Slack's and Teams' payloads, an old layout's subject and body), and a campaign's From and Voice text, suggest the object's variables while typing `{{`, with a `{ }` button to browse them, like the email editor's fields. They follow the class chosen in the form.
- A template's description is made from its sentence and conditions (*Email when User activate, if User › Active? is true*) while Auto is checked, which it is by default (`auto_description`): when they change, or when there's no description yet. Typing one unchecks it. Copy in the migration with `bin/rails nuntius:install:migrations`.
- Conditions on templates and campaigns: *If [all] of the following conditions are met: [Screening › Payment needed?] [is] [true]*, with the Liquid variables they render with and Mensa's operators, chosen as pills. A message is only sent when they're met, so an `{% if %}` around the recipient can go. See [Conditions](README.md#conditions). Copy in the migration with `bin/rails nuntius:install:migrations`.
- Timebased templates send at most `config.timebased_limit` messages in a run (500 by default, or the template's own limit), counted after their conditions. A template that would send more sends nothing, and is disabled and reported (`Nuntius::TimebasedEventsJob::LimitExceeded` through `Rails.error`) until someone checks it. The template's page says whom it sends to today, or this hour. Copy in the migration with `bin/rails nuntius:install:migrations`.
- Every date and time on a nuntiable object is a timebased event: when it *is in* or *was* some time *ago*, once or every day, week, month, quarter, half year or year (a birthday). Templates get a `recurrence`; dates are sent from `config.timebased_send_hour`; messengers can `hide_timestamps`. See [Timebased events](README.md#timebased-events). Copy in the migration with `bin/rails nuntius:install:migrations`.
- The template form reads as a sentence: *Send via Email based on [an event] on [Order] [shipped]*, or based on [a time] when [User] [Born on] [is in] [4] [weeks] [every year]. Objects by their model names, and events by their names from the messenger's `describe`, `nuntius.events` translations or the state machine (see [Naming events](README.md#naming-events)).
- Layouts designed in the email editor, with one Content block where each template or campaign puts its own content. Templates and draft campaigns follow their layout when it changes, and show it locked in their editor.
- Starting layouts for new layouts: Basic, Newsletter, Transactional and Empty.
- A new template starts on a page of cards: what it sends (Email, SMS, Push, …, one for each enabled transport), then for an email which layout to start from, by its preview, name and description. The cards open the editor, and the template is created when it's saved. What a template sends can't be changed afterwards. With one transport, or one layout, it's chosen already.
- An email template is edited in its editor only, without an Edit tab: with the email selected, Inspect has when it sends (its sentence and conditions, as the template form's own fields), its From and To, its subject and preview text, its link and open tracking, and its layout. Its description is the page's title, editable in place, with Enabled beside it. It needs TessEdit's `slot` fields.
- Layouts have a description, saying what they're for. A layout made from a starting layout gets the starting layout's. Copy in the migration with `bin/rails nuntius:install:migrations`.
- The templates page shows the templates of one transport, or all.
- Nuntius blocks in the editor: Content, View in browser and Manage subscription.
- Images uploaded in the editor, by button or by dragging a file onto the canvas, for Image blocks and the backgrounds of heroes, sections and wrappers. They're stored on the layout, template or campaign, and an Image block's image can be embedded in the email.
- The `embed_image` Liquid filter, which attaches an image to the email and returns a `cid:` reference.
- Uploaded images are referred to by a name unique to their layout, template or campaign, not by their URL: the email gets `{{ 'logo.png' | image_url }}` (or `embed_image`), and the `image_url` Liquid filter finds the image in the template's or campaign's images, then its layout's, on the host for the message (`config.host(message)`).
- Converting a template with an old layout to the email editor, from its page in the admin.
- Lettermint webhooks: Nuntius creates and checks the webhook itself and updates messages from Lettermint's events (see [Lettermint](README.md#lettermint)).
- The `soft_bounced` message state, for temporary delivery failures the provider retries.
- Accounts: an `account_id` on templates, campaigns, lists, layouts, old layouts, locales and messages, with the configuration options `account_class`, `current_account`, `account_for` and `can_create_global`, and the scopes `owned_by`, `global` and `available_to`.
- Global templates, used for every account. Only their own account sees them in the admin.
- `account` on messengers, for the account a messenger sends for when its object doesn't say (`account ->(shipment) { shipment.order.account }`). Without an account to send for, a messenger raises `Nuntius::MissingAccountException`.
- A warning on templates, campaigns and layouts in the email editor that still read metadata (`{{ template.metadata.logo_url }}`), and before converting a template whose old layout does.
- The `feedback`, `headers` and `envelope_from` columns on messages, for what was in their metadata.
- The `cancelled` campaign state, with the `cancel` event and a Cancel action in the admin (in the campaigns table, and on the page of a campaign that's scheduled or being sent), for draft, scheduled or sending campaigns that won't be sent (any further). A campaign being sent stops when it's cancelled.
- The `scheduled` campaign state, with the `schedule` and `deschedule` events and Schedule and Back to draft actions in the admin. `Nuntius::CampaignPublishJob` publishes scheduled campaigns at their `publish_at` (run it from cron), or within a minute without one.
- Suggestions of the Liquid variables a design can use in the email editor, from Liquidum's variables endpoint when the host app mounts Liquidum (see [Variables](README.md#variables)). Nuntius's drops are now `Liquidum::Drop`s.
- Translations in the email editor: a `{{ '.greeting' | t }}` shows as its text in a language chosen in the editor, lists every language's text (missing ones marked) when pointed at, each editable there, and selected text can be made translatable under a new key. Typing `{{ '` suggests the keys. Templates, campaigns and layouts get a Translations tab with their keys and texts per language. Texts are saved in the account's locales (see [Locales](README.md#locales)).
- A template's translations move along when its scope changes (its layout, class, event, transport or description, also when converted to a new layout), and a layout's when it's renamed.
- A locale's key is unique in its account, and its data must start with languages (`en`, `pt-BR`), each with its translations under it. YAML that can't be read is a validation error instead of an exception.
- Default views in the admin tables: open (draft and scheduled), sent and cancelled campaigns; enabled and disabled templates; subscribed and unsubscribed subscribers of a list.

### Changed

- **A campaign's translation scope is its layout's** (`basic`), no longer `nuntius` and its layout (`nuntius.basic`), the same as the start of its templates' scopes, so a layout's keys work in both. Move the translations of draft campaigns' keys starting with a dot up from under `nuntius` in the locales.
- An account's locales merge in the order they were created, later ones winning, instead of in no particular order.
- A template with several addresses in its To renders a message for each, instead of the mail and push transports copying one message. `Template#new_message` is deprecated, and gives only the first, no longer one with every address in its To.
- **LMTP is a provider on the `:mail` transport**, no longer a transport of its own: mail to an LMTP address (`<email>@<host>:<port>`) goes to it, other mail to SMTP. Templates and campaigns send by mail, and the migration moves LMTP templates (with their translations), campaigns and messages to `mail`. The LMTP provider is now `Nuntius::LmtpMailProvider`, and its `host` and `port` settings are gone: a plain address goes over SMTP. See [LMTP](README.md#lmtp) and step 13 of [Upgrading from 1.x](#upgrading-from-1x).
- A transport only gives a message to the providers that handle its address (`BaseProvider.handles?`): APNs gets APNs device tokens and Firebase the other push tokens, where both used to get every token. A message no provider handles has no recipient (`no_recipient`). Priorities after a gap (1, then 3) are no longer skipped.
- Every new mail template and campaign needs a layout.
- Mail campaigns to a list that allows unsubscribing must contain the Manage subscription block.
- Campaigns are only published by `Nuntius::CampaignPublishJob`, and only once they're scheduled: `publish` goes from `scheduled` to `sending`, no longer from `draft`, and the admin's Publish action (`POST /admin/campaigns/:id/publish`) is replaced by Schedule. The job no longer publishes draft campaigns whose `publish_at` has passed.
- Templates and campaigns have a preview text.
- The editor compiles MJML on the server, at `<where Nuntius is mounted>/tess_edit/compile`, behind Nuntius' admin authentication.
- A messenger picks the templates of the account it sends for and the global ones, then narrows them with its `template_scope`. A global template is left out for a transport the account has its own template for.
- A message belongs to the account it's sent for, also when the template is global, and no longer copies the template's or campaign's metadata.
- `visible` (what the admin shows) is the current account's records by default. Records of other accounts give a 404 in the admin, also through campaign messages, message trackings and subscribers. A template's layout, and a campaign's list and layout, must belong to its own account.
- Timebased templates are only sent for objects whose messenger picks them, so for their own account's objects (and for a global template, other accounts' too).
- A one-off timebased template is also sent for objects older than the template. It used to skip them, to keep a new template from mailing every existing object of a `timebased_scope`; a date is only due on its day and a time in its hour, so nothing from before the template is sent.
- A template or campaign uses the locales of its own account.
- The admin only edits the metadata of templates that use an old layout. Layouts, lists, locales and messages have no metadata any more; inbound messages keep the provider's parameters as `params`.
- Lettermint events are matched on the message id Nuntius sends as Lettermint metadata (`X-LM-Metadata-nuntius_message_id`), and the Lettermint message id is no longer stored.

### Removed

- **`timebased_scope` no longer works.** A messenger that still calls it gets a warning, and the scope is ignored: no event is made of it, and templates with its event are no longer sent (`Nuntius::TimebasedEventsJob` logs a warning for each). Send around the model's timestamps instead, with conditions for what else the scope selected; see step 10 of [Upgrading from 1.x](#upgrading-from-1x). `Nuntius::MessageMessenger`'s `after_opened`, `after_clicked` and `after_sent` scopes are gone too (they queried screenings); messages' `opened_at`, `clicked_at` and `last_sent_at` are timestamps.
- Markdown and Trix editing of mail templates and campaigns. Templates with an old layout keep sending as before until you convert them.
- The `{{ subscriber_link }}` variable and the `subscriber_url_text` translation; use the Manage subscription block. `Subscriber#link` is replaced by `Subscriber#url(message)`.
- `Nuntius::Concerns::MetadataScoped`, with the jsonb scopes it brought (`metadata_in`, `metadata_eql`, …), and the configuration options `metadata_fields`, `metadata_humanize`, `add_metadata` and `default_template_scope`.
- The metadata columns in the admin tables, and the metadata editors of campaigns, layouts, lists and locales.
- `metadata` on the layout drop.
- The status column (a traffic light) in the templates table, and the `flow_color` configuration option it read. Remove `config.flow_color = …` from your initializer.

### Fixed

- `Nuntius::CampaignPublishJob` raised instead of publishing the campaigns that were due.
- `Nuntius::TimebasedEventsJob` runs one at a time (a Postgres advisory lock): a run that started while another one was still going could send the same messages again. It now leaves them to the run that's going.
- The subscribers table raised for a subscriber with tags.
- The `t` filter raised ("Liquid error: internal") instead of translating with the account's locales, and keys starting with a dot had no scope. It needs Liquidum 1.4 and its configuration (see Upgrading).
- Liquid that doesn't parse in a template's From, To, subject, body or text (`validates …, liquid: true`) is a validation error. The validator added its error in a way Rails no longer keeps, so such templates saved.
- A new layout, template or campaign that didn't save raised (a missing `new` view, or no media URL for the editor) instead of showing its form again. It now shows the form with what was filled in, and with Signum the error notification says why.

### Upgrading from 1.x

1. **Send, delete or cancel draft campaigns first.** The migration refuses to run while campaigns are in draft or sending, and names them, with how many messages each sent. Campaigns now have a `cancelled` state, for campaigns that won't be sent (any further): cancelling a partly sent campaign keeps the messages it sent, and its statistics, where deleting it would lose them. In 1.x there is no way to cancel, so the migration's message gives the SQL: `UPDATE nuntius_campaigns SET state = 'cancelled' WHERE id IN (…)`. Sent and cancelled campaigns keep the HTML they were sent with.
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

   An app that bundles its JavaScript with jsbundling-rails (esbuild) instead of importmap-rails resolves the gems' JavaScript itself: `nuntius` and `nuntius/*` from the nuntius gem's `app/javascript/nuntius/` (`nuntius` is its `application.js`), `tess_edit` and `tess_edit/*` from the tess_edit gem's `app/javascript/tess_edit/` (`tess_edit` is its `index.js`), and `tess_edit/vendor/tiptap` from its `vendor/javascript/tess_edit/tiptap.js`. The README has an esbuild plugin that does this.

4. **Configure accounts** in your Nuntius initializer, replacing `metadata_fields`, `metadata_humanize`, `add_metadata`, `default_template_scope` and `visible_scope` (see [Accounts](README.md#accounts)):

   ```ruby
   # Before
   config.metadata_fields = {account_id: {collection: -> { Account.all.map { |a| [a.name, a.id] } }, current: -> { Current.account.id }}}
   config.metadata_humanize = ->(data) { Account.find_by(id: data["account_id"])&.name }
   config.visible_scope = -> { where("#{table_name}.metadata->>'account_id' = ?", Current.account.id) }

   # After
   config.account_class = "Account"
   config.current_account = -> { Current.account }
   config.can_create_global = -> { Current.account.parent_id.nil? } # if some account makes templates for all
   ```

   `can_create_global` says which account may make templates global: the root of an account hierarchy, as above, or one fixed account, e.g. `-> { Current.account.code == "root" }`.

   `visible_scope` now defaults to the current account's records; leave it out unless the admin should show something else.
5. **Check your data.** The migration takes each record's account from `account_id` in its metadata, as `metadata_fields` filled it, and `global` from `global` in a template's metadata (`true` or `"true"`). Messages without one get their template's or campaign's account. To see what would be left without an account:

   ```sql
   SELECT 'nuntius_templates', COUNT(*) FROM nuntius_templates t
   WHERE NOT EXISTS (SELECT 1 FROM accounts a WHERE a.id::text = t.metadata->>'account_id');
   -- and the same for nuntius_campaigns, nuntius_lists, nuntius_layouts, nuntius_locales and nuntius_messages
   ```

   Layouts, lists and locales lose their metadata. In 1.x it only held the account; when they hold anything else the migration stops, so move it elsewhere first.
6. **Run the migrations:**

   ```sh
   bin/rails nuntius:install:migrations
   bin/rails db:migrate
   ```

   The existing layouts become old layouts (`nuntius_old_layouts`, with their attachments), and templates and campaigns keep them as `old_layout_id`. New layouts go in `nuntius_layouts`. The migrations also add inline attachments (for `embed_image`), `converted_from` on templates and `nuntius_webhooks` (for Lettermint).

   Then every record gets its `account_id` (a foreign key to `config.account_class`'s table, with the same type as its id), templates get `global`, and `account_id` and `global` are taken out of the metadata. Messages get `feedback`, `headers` and `envelope_from` from their metadata, which is dropped with that of layouts, lists and locales. The rest of a message's metadata is dropped with it: Nuntius 1.x copied the template's or campaign's metadata into each message when it was created, but only read `mail` from it when sending, so this loses nothing that was used, and templates and campaigns keep their own metadata. The migration lists the keys it drops, with how many messages had them. Inbound messages' `metadata` becomes `params`. The account migration updates messages 10,000 at a time.

   When records are left without an account, that migration stops, is rolled back and says how many there are per table. Set an existing `account_id` in their metadata, or give them all one account, as an app with a single account would:

   ```sh
   NUNTIUS_ACCOUNT_ID=<account id> bin/rails db:migrate
   ```

   When layouts, lists or locales still have metadata besides their account, that migration stops too. `NUNTIUS_DROP_METADATA=1 bin/rails db:migrate` drops it anyway.
7. **Update your messengers.**
   - Drop `template_scope`s that only selected the account's templates, like `where("metadata->>'account_id' = ? or metadata->>'global' = 'true'", screening.account_id)`: that is what a messenger does now.
   - Rewrite the ones that still need to narrow it down with columns instead of metadata, e.g. `metadata_in("account_id", user.account.self_and_ancestor_ids)` becomes `owned_by(user.account.self_and_ancestor_ids)`.
   - When a messenger's object doesn't know its account (`object.account`), give the messenger an `account`: `account ->(flow) { Account.find(flow.account_id) }`. An account sends for itself, and an object without an account falls back to `config.current_account`, which usually isn't set in jobs.
   - Code that read or wrote `metadata` on messages uses `feedback`, `headers` and `envelope_from`. Direct messages (`Nuntius::Message.new(…)`) need an `account`.
8. **Make new layouts and convert your templates.** Create layouts in the admin, then convert each template with an old layout from its page. Until then it keeps sending with its old layout.

   Translation keys of a template start with its layout's name. Converting it to a layout with another name moves its translations to the new layout's scope.

   Values the old layout read from the template's metadata, like `{{ template.metadata.logo_url }}`, should come from a drop in the new design, like `{{ user.account.logo_url }}`. The template's page shows which ones its old layout reads, and what their value is, before you convert; after converting, it warns about any left in the design.
9. **Replace `{{ subscriber_link }}`** in your own templates with the Manage subscription block, or with a link to `{{ subscriber_url }}`.
10. **Replace your `timebased_scope`s** with templates around the model's timestamps, before you deploy: templates whose event is a scope's stop sending. For each scope:

    - Find the timestamp it selects on: a date or datetime column, or an `_at` key of a store (`store_accessor :event_stamps, :processed_at`). The events are `before_<timestamp>` (*is in*) and `after_<timestamp>` (*was … ago*).
    - Make what else it selected conditions on the template.
    - Change its templates' `event` in a data migration, and add the conditions; then remove the scope from the messenger.

    ```ruby
    # Before, in ScreeningMessenger
    timebased_scope :after_processed do |time_range, template|
      Screening.where("date(event_stamps->>'processed_at') BETWEEN ? AND ?", time_range.first, time_range.last).where(state: "processed")
    end

    # After, in a data migration
    Nuntius::Template.where(klass: "Screening", event: "after_processed").find_each do |template|
      rules = template.conditions.fetch("rules", []) + [{"variable" => "screening.state", "operator" => "is", "value" => "processed"}]
      template.update!(event: "after_processed_at", conditions: {"match" => "all", "rules" => rules})
    end
    ```

    A timestamp that's a time is due in the hour its interval is up, a date (or a template with a recurrence) on its day from `config.timebased_send_hour`.
11. **Configure Liquidum's translations** (Liquidum 1.4 or later), so the `t` filter translates with the account's locales. `Nuntius.i18n_store` is gone:

    ```ruby
    # config/initializers/liquidum.rb
    Liquidum.setup do |config|
      config.i18n_store = ->(context) { Nuntius::I18nStore.backend(context) }
      config.translation_scope = ->(context) { Nuntius::I18nStore.translation_scope(context) }
    end
    ```

    Campaigns' keys starting with a dot are now in their layout's scope, without `nuntius` (see Changed): move them up in the locales.

12. **Check your locales.** A locale that has the same key as another of its account, or data that doesn't start with languages, can't be saved any more. Find them with `Nuntius::Locale.all.reject(&:valid?)`, and merge or fix them.

13. **Move LMTP to the mail transport** in your Nuntius initializer, if you use it: remove `config.transport :lmtp`, give the LMTP provider `transport: :mail`, and drop its `host` and `port` settings:

    ```ruby
    config.provider :lmtp, transport: :mail, settings: {
      from_header: "Example <example@example.com>",
      allow_list: ["example.com"]
    }
    ```

    LMTP templates need a To that renders to LMTP addresses (`<email>@<host>:<port>`): a plain address now goes over SMTP.
