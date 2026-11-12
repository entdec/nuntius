# Template editor redesign

Plan of 2026-11-12. Users pick what they send (Email, SMS, Push, …) once,
when creating a template, and then edit everything in one editor: TessEdit
for email, a frame like it for the other transports. LMTP stops being
something users see: it becomes a mail provider.

Each step is its own commit (or series of commits).

## 1. LMTP as a provider on `:mail`

Done.

Within a transport, every provider gets every message, as interchangeable
fallbacks (`BaseTransport#deliver`). SMTP and LMTP aren't interchangeable,
which is the only reason LMTP has its own transport. Providers will say
which addresses they deliver to instead.

- Providers get a class method `handles?(to)`, `true` by default:
  - `LmtpMailProvider` (renamed from `LmtpLmtpProvider`): `email@host:port`
  - `SmtpMailProvider`: everything else
  - `ApnoticPushProvider`: 64 character hex tokens; `FirebasePushProvider`:
    the rest. Today both get every token, and APNs returns silently.
- The `email@host:port` pattern moves out of the LMTP provider into one
  small object, used by both LMTP and SMTP.
- `BaseTransport` only enqueues the providers that handle the message's
  `to`, so priorities and fallbacks stay among providers that can deliver.
  When none does, the message becomes `no_recipient`.
- Removed: `LmtpTransport`, `config.transport :lmtp`, and `lmtp` in
  `EMAIL_TRANSPORTS`, `Template::ADDRESS_ATTRIBUTES` and the locales.
  Configuration becomes `config.provider :lmtp, transport: :mail, …`
  (generator template, dummy app, README, CHANGELOG).
- Migration:
  - templates and campaigns from `lmtp` to `mail`, with `update!` so their
    translations move along (the transport is part of `translation_scope`)
  - messages from `lmtp` to `mail`, so resend and refresh still find their
    provider
- The LMTP provider's `host` and `port` settings go: they were the fallback
  server for a plain address, which now always goes over SMTP. Every LMTP
  address carries its own server (`email@host:port`). Its "falls back to the
  configured host/port" test goes with them.

## 2. The New template page

Done.

One page, two stages, with cards of equal size in one grid. The cards are
links: nothing is created until the template is saved in its editor, so
there's no button to confirm a choice.

**Stage 1: what to send.** A card per enabled transport: Email, SMS, Push,
Teams, Slack, Voice, each with an icon, its name and one line about it.

```
 New template
 What do you want to send?
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │      ✉       │ │      💬      │ │      🔔      │
 │    Email     │ │     SMS      │ │     Push     │
 └──────────────┘ └──────────────┘ └──────────────┘
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │   [Teams]    │ │   [Slack]    │ │      ☎       │
 │    Teams     │ │    Slack     │ │    Voice     │
 └──────────────┘ └──────────────┘ └──────────────┘
```

- Every card has an icon. Email, SMS, Push and Voice use Font Awesome, like
  the rest of the admin. Teams and Slack use their product logos: Slack's is
  in Font Awesome's brand icons (`fa-brands fa-slack`); Font Awesome has no
  Teams logo, so that one ships with the engine as an SVG, and Slack's too
  if the host's Font Awesome kit has no brand icons. The icons sit in one
  helper, by transport, so the index's filter tabs and the editors use the
  same ones.

- The question is the page card's description, under its title.
- A card opens the transport's editor; Email goes to stage 2.
- With one transport enabled, this stage is skipped.

**Stage 2: which layout (Email).** The transport cards make way for the
layouts: a preview, the name and the description. A layout opens the
editor.

```
 New template                                       [ Back ]
 Email › Which layout do you want to start from?
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
 │  [preview]   │ │  [preview]   │ │  [preview]   │
 ├──────────────┤ ├──────────────┤ ├──────────────┤
 │ Default      │ │ Newsletter   │ │ Event        │
 │ Plain trans… │ │ Header, col… │ │ Date and lo… │
 └──────────────┘ └──────────────┘ └──────────────┘
```

- The preview is the layout's compiled HTML in a scaled-down
  `iframe srcdoc` (`loading="lazy"`, no pointer events, so the whole card is
  clickable), with its Liquid rendered without values. Its Content block
  shows the layout's example content.
- With one layout, it's chosen already. With none, stage 2 shows a
  "Create a layout first" card linking to New layout.
- The question is the page card's description, and Back a button in its
  header, to the transport cards (none when Email is the only transport).
  The browser's Back button works too.

**Details**

- A card links to `new` with `transport` (and `layout_id`): the editor
  opens with a new, unsaved template, and its first Save creates it. So
  nothing is left behind when someone picks the wrong card or leaves.
- Until that first Save, the editor of the new template has a Back button
  in its header, to the choice it was made from: the layout cards for an
  email (with more than one layout), else the transport cards. None when
  there was nothing to choose.
- Until that first Save, the parts that need a record aren't there, as
  before: the Media and Translations tabs, and image uploads (attached to
  the template). Uploading images before saving, as loose blobs attached on
  Save, can come later; the Image block already works with blob signed ids.
- The server renders each stage, so no JavaScript and no wizard state.
- Layouts get a `description`: a migration, a field on the layout form, and
  descriptions for the starting layouts (Basic, Newsletter, Transactional),
  copied when a layout is created from one.
- The transport is fixed once created: the "Send via" pill becomes text,
  and the form renders only that transport's fields.
- The templates index gets filter tabs (All, Email, SMS, Push, …) instead of
  submenus, as the host app owns the sidebar. The templates table filters
  on `transport` and `layout_id` (the layout page's Templates tab passed
  `layout_id`, but the table ignored it).

## 3. Everything in root Inspect; the Edit tab goes

Done. Enabled's second switch, in When, is kept in step with the card's by
the `nuntius--mirror` controller (only the card's is submitted). TessEdit
calls its subject and preview text group Message now. The layout is chosen
in a slot in the Layout group.

**TessEdit** (on a branch in its own repository):

- A `slot` field type: the host renders the element server-side, and the
  inspector moves it in and out (never recreates it, so its Stimulus state
  survives). Its values stay ordinary form fields, outside the design JSON.
  A `summary(element)` hook shows it collapsed ("Account · created").
- `variablesUrlValueChanged`, so the editor reloads its variables when the
  class changes.

**Nuntius** adds to the root, with `extendBlock("email")` and in
`EDITOR_LOCK[:fields]`:

| Group     | Fields                                          |
|-----------|-------------------------------------------------|
| When      | Trigger sentence and conditions (slot), Enabled |
| Recipient | From, To                                        |
| Message   | Subject, Preview text (as now)                  |
| Tracking  | Links, Opens                                    |
| Layout    | Locked, as now                                  |

- `assign_design` takes From, To and the tracking settings like it takes the
  subject.
- The trigger keeps `entdec_pill_select`, `nuntius_conditions`, the
  description controller and its validations; its errors show in the slot,
  and the editor selects the root after a failed save. Changing the class
  updates the variables URL (`nuntius--variables` controller).
- The description becomes the card title: generated by default, editable in
  place. Enabled is also a toggle in the card's actions.
- The Edit tab goes for email. Templates on an old layout keep their convert
  screen until converted.

## 4. Editors for SMS, Push, Teams, Slack and Voice

Done, as a TessEdit kit per transport without blocks
(app/javascript/nuntius/kits/messages.js). The sample values are each
variable's name, ‹User › Name› (Nuntius::TemplatePreview), not a record's,
so no account's data shows. Push has no Title: its providers send none yet.
The links to the designers are in the preview (TessEdit's data-tess-open).

TessEdit's frame: a preview in the middle, the same Inspect partial (When,
Recipient) on the side, plus a Message group per transport.

```
 ┌───────────────────────────────┬──────────────────────┐
 │        ┌───────────┐          │ SMS                  │
 │        │ 9:41      │          │  When  Account ·     │
 │        │ ┌───────┐ │          │        created [edit]│
 │        │ │Hi Tom,│ │          │  Enabled [●]         │
 │        │ │your … │ │          │ Recipient            │
 │        │ └───────┘ │          │  To {…}  From {…}    │
 │        └───────────┘          │ Message              │
 │                               │  Text {…}            │
 │                               │  42 / 160 · 1 SMS    │
 └───────────────────────────────┴──────────────────────┘
```

| Transport | Message group                          | Preview                        |
|-----------|----------------------------------------|--------------------------------|
| SMS       | Text, character and segment counter    | Phone with a text bubble       |
| Push      | Title, text, payload (YAML)            | Lock screen notification       |
| Teams     | Text, card payload (YAML)              | Card JSON, link to the designer |
| Slack     | Text, blocks payload (YAML)            | Blocks, link to Block Kit Builder |
| Voice     | TwiML                                  | Highlighted TwiML              |

The preview renders the Liquid with sample values, through a small preview
endpoint.

## Later

- Campaigns the same way, with "To which list?" instead of the trigger.
- A default From per layout, if brands need their own sender (for now the
  provider's `from_header` is the default).
- A TessEdit voice kit, only if Voice gets used much (it hardly is now):
  root Call (voice, language), Step blocks (one script per `path`), Say,
  Play, Pause, Gather, Dial, Redirect, Hangup, with Condition and Loop; a
  call script as the canvas; `text` in today's format, so
  `TwilioVoiceProvider` stays as it is. It would also avoid the blank-line
  pitfall of `script_for_path`, which splits the scripts on blank lines.
