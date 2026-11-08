# Nuntius

Nuntius offers messaging and notifications for ActiveRecord models in Ruby on Rails applications.

## Setup

Add Nuntius to your Gemfile. It brings [TessEdit](https://github.com/tdegrunt/tess_edit), the email editor it uses, from RubyGems.

```ruby
gem "nuntius"
```

Run bundle install, then copy the migrations and run them:

```sh
bin/rails nuntius:install:migrations
bin/rails db:migrate
```

Nuntius' admin pages need [Satis](https://github.com/entdec/satis), importmap-rails, Propshaft and Tailwind CSS 4 through tailwindcss-rails 4.3 or later (for engine support). Import Nuntius' JavaScript after Satis, whose Stimulus application it uses:

```js
// app/javascript/application.js
import "satis"
import "nuntius"
```

and add the styles of Nuntius, the email editor and the forms' view components ([entdec-view_components](https://github.com/entdec/view_components), a dependency from GitHub: add `gem "entdec-view_components", github: "entdec/view_components"` to your Gemfile) to your Tailwind CSS:

```css
/* app/assets/tailwind/application.css */
@import "../builds/tailwind/nuntius";
@import "../builds/tailwind/tess_edit";
@import "../builds/tailwind/entdec_view_components";
```

With jsbundling-rails (esbuild) instead of importmap-rails, your build has to find the gems' JavaScript, which imports its own modules by importmap names without `.js`: `nuntius` is the nuntius gem's `app/javascript/nuntius/application.js` and `nuntius/x` its `app/javascript/nuntius/x.js`, `tess_edit` is the tess_edit gem's `app/javascript/tess_edit/index.js` and `tess_edit/x` its `app/javascript/tess_edit/x.js`, except `tess_edit/vendor/tiptap`, which is its `vendor/javascript/tess_edit/tiptap.js`, and `entdec/view_components` is the entdec-view_components gem's `app/javascript/entdec/view_components.js` and `entdec/components/x` its `app/components/entdec/x.js`. For example, with a plugin in your esbuild config:

```js
// esbuild.config.mjs
import { execSync } from "node:child_process"

const gem = (name) => execSync(`bundle show ${name}`).toString().trim()
const roots = { nuntius: [gem("nuntius"), "application"], tess_edit: [gem("tess_edit"), "index"] }

const gems = {
  name: "gems",
  setup(build) {
    build.onResolve({ filter: /^tess_edit\/vendor\/tiptap$/ }, () => ({ path: `${roots.tess_edit[0]}/vendor/javascript/tess_edit/tiptap.js` }))
    build.onResolve({ filter: /^(nuntius|tess_edit)(\/|$)/ }, ({ path }) => {
      const [name, ...rest] = path.split("/")
      const [root, index] = roots[name]
      return { path: `${root}/app/javascript/${name}/${rest.join("/") || index}.js` }
    })
  }
}
// and plugins: [gems] in your esbuild options
```

Images uploaded in the email editor and on the Media tabs are stored with [Active Storage](https://guides.rubyonrails.org/active_storage_overview.html), so your app needs it set up (`bin/rails active_storage:install`). The Media tabs show previews of images through [image_processing](https://github.com/janko/image_processing), which Nuntius depends on; it needs [libvips](https://www.libvips.org) on every server that runs the admin, e.g. `apt-get install libvips` (Debian, Ubuntu) or `brew install vips` (macOS). Without it, opening a Media tab with an image on it fails.

Create an initializer (config/initializers/messaging.rb) and configure as desired:

```ruby
Nuntius.setup do
  # Have Nuntius log to the Rails.logger
  config.logger = Rails.logger

  # Allow custom events (default = false)
  # Enable this option to allow use of Nuntius with a Hash
  config.allow_custom_events = true

  # Configure the transport you want to use

  # Enable e-mail
  config.transport :mail
  # Enable push notifications
  config.transport :push
  # Enable SMS
  config.transport :sms
  # Enable voice
  config.transport :voice
  # Enable Slack
  config.transport :slack

  # Every template, campaign, list, layout, locale and message belongs to an account (see Accounts below)
  config.account_class = "Account"
  config.current_account = -> { Current.account }

  # Configure providers for each of the transports you enabled above.
  # Advised is to either do this using credentials, environment variables, or somewhere in a model (securely stored away).
  config.provider :slack, transport: :slack, settings: lambda { |_message|
    Rails.application.credentials[:slack]
  }
end
```

Mount the Rails engine in your routes.rb to enable Nuntius' maintenance pages:

```ruby
Rails.application.routes.draw do
  # your own routes ...
  mount Nuntius::Engine, at: '/messaging', as: 'nuntius' # change the path and aliases at your own discretion
end
```

To enable you to send messages with Nuntius you need to make one or more ActiveRecord models nuntiable:

```ruby
class Car < ApplicationRecord
  nuntiable
end
```

Additionally you need to define an extension of the Nuntius::BaseMessenger for the same model with a matching name (in app/messengers). Messengers can set extra parameters, but also manipulate templates selected.

```ruby
class CarMessenger < Nuntius::BaseMessenger
  def your_event(car, params)
    # your optional logic here, you could add attachments here
    pdf = ApplicationController.renderer.new(http_host: object.account.hostname, https: true).render(template: "commercial_invoice/show", formats: [:pdf], assigns: {order: object})

    attachments << {content: StringIO.new(pdf), content_type: "application/pdf", filename: "commercial_invoice.pdf"}
    # Return false here if you don't want the message to be sent
  end
end
```

If you are using the state_machines-activemodel gem you can pass use_state_machine: true to the
nuntiable call, this will automatically define empty methods for these events on the model's
messenger class if they are not defined already.

Additionally the use_state_machine option will add an after_commit hook to the state machine
to automatically trigger the event for the state transition.

### Accounts

Every template, campaign, list, layout, locale and message belongs to an account: a record of your app's own account model, by default `Account` (each Nuntius table has an `account_id` foreign key to its table). Subscribers belong to one through their list. Customers can then run their own campaigns, with their own layouts and lists, while you send your own mail with templates they never see.

```ruby
Nuntius.setup do |config|
  # Your account model
  config.account_class = "Account"
  # The account of the current request: new records get it, and the admin shows its records only
  config.current_account = -> { Current.account }
  # The account a messenger sends for, given its object. The default: the object itself when it is an account,
  # else its account, else the current account.
  config.account_for = ->(object) { object.account }
  # Whether the current account may make templates global (default: no account may), e.g. the root
  # account of a hierarchy, or one fixed account: -> { Current.account.code == "root" }
  config.can_create_global = -> { Current.account.parent_id.nil? }
  # The records the admin shows, a scope on each model (default: the current account's)
  config.visible_scope = -> { owned_by(Nuntius.config.current_account) }
end
```

The models have the scopes `owned_by(accounts_or_ids)`, `visible`, and on templates `global` and `available_to(account)` (its own templates and the global ones).

**Sending.** A messenger sends for an account, from `config.account_for`, or from its own `account` when its object doesn't say. Subclasses inherit it:

```ruby
class ShipmentMessenger < ApplicationMessenger
  account ->(shipment) { shipment.order.account }
end
```

It picks the enabled templates for the event that are the account's own or global, then narrows them with its `template_scope`, a scope on the templates given the object. When the account has its own template for a transport, global templates for that transport are left out. The message belongs to the account it's sent for, also when the template is global; a campaign's messages belong to the campaign's account. When there are templates for the event but no account to send for, the messenger raises `Nuntius::MissingAccountException`.

**Global templates.** A global template is used for every account, not only for its own. Only its own account sees it in the admin: the accounts it sends for see its messages, not the template. When your accounts have sub-accounts and a global template should only reach the accounts below its own, say so in `template_scope`:

```ruby
class UserMessenger < ApplicationMessenger
  template_scope ->(user) { owned_by(user.account.self_and_ancestor_ids) }
end
```

**The admin** shows, creates and changes the `visible` records only: other accounts' records give a 404. New records get the current account. A template's layout, and a campaign's list and layout, must belong to its own account. The template form has a Global switch when `config.can_create_global` allows it.

## Usage

### With templates

Usually you would call Nuntius programatically with code by using Templates. In this case you would use for example:

```ruby
 Nuntius.event(:your_event, car)
```

When custom events are enabled you can also do the following:

```ruby
 Nuntius.event('shipped', { shipped: { to: 'test@example.com', ref: 'Test-123'} }, attachments: [ { url: 'http://example.com' } ])
```

For the above cases you need to define templates, this is done with the maintenace pages under
/messaging/admin/templates (/messaging is whatever you have defined in your routes file).

When an event is fired a message is sent for every matching template of the account it's sent for (see
[Accounts](#accounts)). To send different messages under different circumstances you can specify a
template_scope on the messenger class, a scope on the templates given the nuntiable object, that
narrows down which templates are used:

```ruby
class CarMessenger < Nuntius::BaseMessenger
  template_scope ->(car) { where(transport: car.owner.prefers_sms? ? "sms" : "mail") }
end
```

### Naming events

The template form reads as a sentence: *Send via [Email] based on [an event] on [Order] [shipped]*,
or based on [a time] (see [Timebased events](#timebased-events)). The object is
its model's `model_name.human`, the transports are in alphabetical order (new templates send by mail),
and an event's name comes from the first of:

1. the messenger's `describe`:

   ```ruby
   class OrderMessenger < ApplicationMessenger
     describe :after_shipped, label: -> { I18n.t("orders.events.after_shipped") }
   end
   ```

2. a Nuntius translation, `nuntius.events.<model>.<event>`:

   ```yaml
   nl:
     nuntius:
       events:
         order:
           ship: is verzonden
           after_shipped: na verzending
   ```

3. the state machine's own name for the event, `activerecord.state_machines.<model>.events.<event>`
   (from state_machines' translations), for the events of `nuntiable use_state_machine: true`;
4. the event itself, `after shipped`.

Name an event for how it reads after the object: "on Order *shipped*". The transports' names are
`nuntius.transports.<transport>`.

### Timebased events

Every date and time on the object is an event: its date and datetime columns, and the `_at` keys
of its stores (`store_accessor :event_stamps, :processed_at`).
A template is sent when one *is in* or *was* some time *ago*, once or again and again:

- Send via [SMS] based on [a time] when [User] [Born on] [is in] [4] [weeks] [every year]
- Send via [Email] based on [a time] when [Screening] [Processed at] [was] [2] [weeks] ago [once]

Their events are `before_<name>` and `after_<name>`, so `before_born_on` with the interval
`4 weeks` and the recurrence `yearly`. A recurrence (every day, week, month, quarter, half year or
year) sends on each day the date comes round again, a month on from January 31 being February 28;
once a day, also for objects older than the template. Dates are sent from
`config.timebased_send_hour` (9 by default), times in the hour they're due. An interval of `0 days`
is the day itself.

`updated_at` is left out; leave out more in the messenger, and name the ones people see:

```ruby
class UserMessenger < ApplicationMessenger
  hide_timestamps :synced_at
  describe :born_on, label: -> { I18n.t("users.birthday") }  # [birthday] [is in] [4] [weeks]
end
```

When there's more to it than the date, add conditions: *[Screening] [Processed at] [was] [2] [days]
ago*, if *[Screening › State] [is] [processed]* (see [Conditions](#conditions)). Messengers'
`timebased_scope` is no longer supported, and ignored with a warning.

The interval is a number of minutes, hours, days, weeks or months.

To send timebased messages, run `Nuntius::TimebasedEventsJob` every few minutes: with Sidekiq::Cron
or GoodJob's cron, or a cronjob running `bin/rails runner 'Nuntius::TimebasedEventsJob.perform_now'`.

A timebased template is only sent for the objects whose messenger picks it (see [Accounts](#accounts)): those of its own account, and for a global template those of the other accounts too, unless they have their own template for the event and transport.

A template is sent once for each object, or with a recurrence once a day, also when runs of the
job overlap: a run while another one is going sends nothing. As a date is only due on its day and a
time in its hour, a new template is never sent for dates that have passed, also for objects older
than the template.

A template sends at most `config.timebased_limit` messages in a run (500 by default), counted after
its conditions; a template can set its own limit. One that would send more sends nothing: it's
disabled, logged and reported with `Rails.error` (`Nuntius::TimebasedEventsJob::LimitExceeded`), so
a mistake doesn't mail everyone. Check its event and conditions, or raise its limit, and enable it
again. The template's page says whom it sends to now: today for a date (or with a recurrence), this
hour for a time.

```ruby
Nuntius.setup do
  config.timebased_limit = 1000
end
```

### Conditions

A template or campaign can send only when its conditions are met: *If [all] of the following conditions are met: [Screening › Payment needed?] [is] [true]*. Instead of a Liquid `if` around the recipient,

```liquid
{% if screening.payment_needed? %}{{ screening.screening_profile.contact.email }}{% endif %}
```

the template's To is `{{ screening.screening_profile.contact.email }}` with that condition. When they aren't met there's no message.

A condition is one of the Liquid variables the template or campaign renders with (see [Variables](#variables)), compared with *is*, *isn't*, *contains*, *doesn't contain*, *is more than*, *is at least*, *is less than*, *is at most*, *is between*, *is empty* or *isn't empty*: text ignoring case, numbers as numbers, dates and times as dates and times, and true or false as *true*, *yes* or *1*. A list *is* or *contains* a value when one of its elements does. The admin offers the operators for the variable's type, and a variable ending in `?` is true or false.

The form chooses the variables with Liquidum's endpoint, so your app needs to mount it (see [Variables](#variables)); without it they're typed in, like `screening.payment_needed?`. They're stored in a `conditions` column (`{"match" => "all", "rules" => [{"variable", "operator", "value", "value_to"}]}`): copy in the migration with `bin/rails nuntius:install:migrations`. A campaign checks its conditions for each subscriber, with `campaign`, `subscriber` and the subscriber's object.

### Locales

Nuntius supports locale support in it's mails. You can add locales for your emails per language:

Add a locale with key `en`:
```yaml
en:
  salutation: "Hello %{name}"
```

Then in your template you can do:
```liquid
{{'salutation' | t name: {{car.owner}} }}
```

Locales belong to an account, like templates. A template uses the locales of its own account, so a global template uses its owner's.

### Metadata

Old layouts (from before Nuntius 2) can read values from the template's or campaign's metadata. The admin only edits a template's metadata while it uses an old layout. Designs in the email editor shouldn't read metadata: take the value from a drop instead, like `{{ user.account.logo_url }}`. The edit pages of templates, campaigns and layouts in the email editor warn about metadata variables they still use, with the value the template's metadata has for each; a template's conversion does the same for its old layout. Layouts made in the email editor have no metadata at all, so `{{ layout.metadata.… }}` is always empty.

Subscribers have metadata of their own, like the extra columns of an import, which you can use as `{{ subscriber.metadata.organisation }}`.

How an old layout reads metadata:

Say you need to change the header of an email, based on the template. In your layout you can then do this:

```html
<h2>{{template.metadata.header}}</h2>
```

And in you template metadata:

```yaml
header: You lost your password?
```

Say your layout has a logo image, which needs to change based on the brand of the car.
In your layout html you can do the following, to grab

```html
<img src="{%render template.metadata.logo_url%}" alt="logo"/>
```

in your template metadata:
```yaml
logo_path: "{{car.brand.logo_path}}"
```
### Direct

Another more direct way of using Nuntius is by just instantiating a message:

```ruby
 Nuntius::Message.new(to: 'test@example.com', subject: 'Test', text: 'Test text', nuntiable: channel, account: channel.account).deliver_as(:mail)
```

or

```ruby
user = User.find(1)
user.messages.new(to: 'test@example.com', subject: 'Test', text: 'Test text', account: user.account).deliver_as(:mail)
```

A message needs an account; without one it gets the current account.

Here we still need a nuntiable object, in case provider settings can differ from object to object.

You can also define custom events, which take a scope and an event name:

```ruby
Nuntius.event('packed', packing: {smurrefluts: 'hatseflats'})
```

The main key of the hash passed will also be the liquid variable.

## Email designs

Mail and LMTP templates and campaigns are designed in an email editor ([TessEdit](https://github.com/tdegrunt/tess_edit)), which builds [MJML](https://mjml.io); Nuntius compiles it to HTML with [MRML](https://github.com/jdrouet/mrml). Liquid works everywhere in the design and is rendered when a message is sent.

### Layouts

A layout is the part every email shares: header, footer, width, fonts, colors and CSS. It has exactly one **Content** block, where each template or campaign puts its own content. A new layout starts from one of the starting layouts Nuntius ships: Basic, Newsletter, Transactional or Empty.

Templates and campaigns follow their layout: when you change a layout, every template and draft campaign that uses it is put together again with the new layout. In their editor the layout's parts are visible but locked; only the Content block, the subject and the preview text are theirs.

Besides TessEdit's blocks, the editor has three Nuntius blocks:

- **Content**, the template's or campaign's own part of the layout
- **View in browser**, a link to the message online (`{{ message_url }}`)
- **Manage subscription**, a link to the subscriber's page for the campaign's list (`{{ subscriber_url }}`). Campaigns to a list that allows unsubscribing must contain it.

### Templates and campaigns

Every new mail or LMTP template and campaign needs a layout. Choose it on the Edit tab and save; the email is then edited on the Design tab, starting with the layout's example content. Choosing another layout moves the content into it.

### Variables

The editor suggests the Liquid variables a design can use while typing `{{`, and its `{ }` buttons browse them, when your app mounts [Liquidum](https://github.com/entdec/liquidum)'s engine:

```ruby
# config/routes.rb
mount Liquidum::Engine => "/liquidum"
```

A template's variables are the object it's sent for, by the name its messenger gives it (`account` for a template of class Account), and `template`; a campaign's are `campaign`, `subscriber`, `subscriber_url` and what its list's subscribers are; a layout's are `template` and `campaign`, one of which is there when it's sent. Each is described by its drop: Liquidum lists what a drop exposes, labelled with the model's `human_attribute_name`, and follows its associations. Your drops need to be `Liquidum::Drop`s for that (`class ApplicationDrop < Liquidum::Drop`); see Liquidum's README for `describe`, to add what it can't work out. Variables a messenger sets itself aren't suggested.

The endpoint runs behind your app's `ApplicationController` (Liquidum's `config.parent_controller`), and only describes the variables, never a record's values. The editor's URL carries the variables signed, so it can't be used for other classes.

### Images

Images in the editor (Image blocks, and the background images of heroes, sections and wrappers) are either a URL or an uploaded image. Upload one with the Upload button in Inspect, or drag a file from your desktop onto the canvas. Uploads are stored on the layout, template or campaign being edited, and also show on its Media tab; a template or campaign can use its own images and its layout's.

The design refers to an uploaded image by its name, which is unique on the layout, template or campaign (a second `logo.png` becomes `logo-2.png`), and the email by Liquid: `{{ 'logo.png' | image_url }}`. The `image_url` filter looks the name up in the template's or campaign's own images, then its layout's, and gives its URL on Nuntius' host for the message (`config.host(message)`), so a design copied to another environment or sent for an account with its own host shows its images from there. Designs from before names still work: their image URLs are left as they are until the design is opened in the editor and saved, which turns them into names.

Images are loaded from Nuntius' host (`config.host`) when the email is opened. An uploaded image in an Image block can be sent with the email instead: turn on **Embed in the email**. That makes emails larger, but the image shows without the reader loading images. Background images are always loaded from their URL, since many mail clients don't show embedded backgrounds.

### Embedded images

Images are normally loaded from their URL. To send an image with the email instead, use the `embed_image` filter: it attaches the image and returns a `cid:` reference to it.

```liquid
{{ 'logo.png' | embed_image }}
{{ 'https://www.example.com/logo.png' | embed_image }}
{{ template.layout.attachments.first | embed_image }}
```

It takes the name of an uploaded image (as `image_url` does), a URL, or a stored file (Active Storage), such as the files on a layout's Media tab, and attaches each image once, however often an email uses it. The online version of the message shows embedded images from storage.

### Converting old templates

Templates made before Nuntius 2 have an old layout (an HTML layout with `{{ content }}`) and a Markdown or HTML body. They keep working as they are. To move one to the email editor, open it, choose a layout under "Convert into layout" and convert it: its body goes into one HTML block in the layout's Content block, exactly as it is sent now, and its old layout and body are kept in `converted_from`.

Liquid that MJML can't take is written another way that means the same (`a < b` becomes `b > a`; double quotes in Liquid inside an attribute become single quotes). A template with Liquid that compares with `<` or `>` inside an HTML tag, like `<span {% if late > 0 %}style="color: red"{% endif %}>`, isn't converted: put the condition around the tag first.

## Transports

### Mail

Outbound mail is handled through SMTP (the `:smtp` provider on the `:mail` transport). LMTP delivery to a mailbox is available through a separate `:lmtp` transport (see below). Mail is designed in the email editor (see [Email designs](#email-designs)); the text version is made from the HTML.

In a layout the View in browser block links to the online version of the message. In old layouts you can add `<a href="{{message_url}}">Link to mail</a>` for that.

Nuntius supports email tracking, to enable this, you need to enable tracking for a template.
Nuntius will then inject a tracking pixel and track clicks on links.

Per link you can disable tracking by adding `data-nuntius-tracking="false"` to the link.

#### AWS SES

In case you use AWS SES, you can use the SNS Feedback Notifications to automatically mark messages as read, or deal with complaints and bounces. Create a AWS SNS topic, with a HTTPS subscription with the following URL (pattern):

Use the following URL: https://<host>/messaging/feedback/awssns

The actual URL may be different depending on your routing setup.

The subscription will automatically be confirmed.

Next in AWS SES, configure the SNS topic to receive feedback notifications for Bounce, Complaint and Delivery and include original headers.

#### Lettermint

When you send mail through [Lettermint](https://lettermint.co) (e.g. with the `:smtp` provider pointed at Lettermint's SMTP server), Nuntius receives message status updates, opens and clicks through a Lettermint webhook. You don't create the webhook in Lettermint yourself, Nuntius does that through Lettermint's API:

```ruby
Nuntius.setup do |config|
  config.lettermint_webhook(
    api_token: ENV["LETTERMINT_TEAM_TOKEN"], # Lettermint Team API token, used to manage the webhook
    project_id: "your-project-id",
    route_id: "your-route-id",               # optional, limits the webhook to one route
    host: "https://app.example.com",         # where Nuntius is reachable, defaults to config.host
    name: "Nuntius",                         # optional, the webhook's name in Lettermint
    setup_on_boot: true                      # optional, check the webhook on server start (the default)
  )
end
```

How it works:

1. **Setting up the webhook.** On every server start (not in tests, consoles or rake tasks) Nuntius enqueues `Nuntius::LettermintWebhookSetupJob`. It looks the webhook up in Lettermint (by the id it stored, or else by its URL), creates it when it's missing, and updates it when its URL, events, scope, project or route changed. When Nuntius has no secret for it yet, it has Lettermint regenerate the secret. The webhook's id and signing secret are stored in `nuntius_webhooks`. An advisory lock makes sure only one process does this when several start at once. You can run it by hand with `bin/rails nuntius:lettermint:setup_webhook`.
2. **Receiving events.** Lettermint posts events to https://&lt;host&gt;/messaging/feedback/lettermint (depending on where you mount Nuntius). Nuntius checks the `X-Lettermint-Signature` header against the stored secret (HMAC-SHA256 of the timestamp and body) and refuses deliveries without a valid signature or more than 5 minutes old.
3. **Finding the message.** Nuntius sends its message id with every mail as Lettermint metadata (an `X-LM-Metadata-nuntius_message_id` header, which Lettermint doesn't pass on), and Lettermint returns it with every event. Nuntius finds the message by it, falling back to the `X-Nuntius-Message-Id` and `Message-ID` headers.
4. **Updating the message.** Events update the message as below, and are stored in its `feedback`. Events can arrive out of order: a `sent` or `soft_bounced` event doesn't undo a later state, and `delivered` doesn't undo a bounce or complaint.

| Lettermint event         | Message                          |
|--------------------------|----------------------------------|
| `message.sent`           | sent                             |
| `message.delivered`      | delivered                        |
| `message.hard_bounced`   | bounced                          |
| `message.soft_bounced`   | soft_bounced (temporary, Lettermint retries) |
| `message.spam_complaint` | complaint                        |
| `message.failed`         | undelivered                      |
| `message.suppressed`     | blocked                          |
| `message.policy_rejected`| rejected                         |
| `message.opened`         | `opened_at` / `open_count`       |
| `message.clicked`        | `clicked_at` / `click_count` and link tracking |

Opens and clicks require open/click tracking to be enabled on the Lettermint route. Lettermint's test event (`webhook.test`) is accepted and ignored.

When the host or route changes, the webhook is updated on the next server start. If you delete the webhook in Lettermint, it's created again (with a new secret).

### LMTP

LMTP (RFC 2033) delivers a message directly to a mailbox. It is its own transport, so it never interferes with `:mail`/SMTP delivery. Enable the transport and provider, and give the relevant templates `transport: "lmtp"`:

```ruby
config.transport :lmtp
config.provider :lmtp, transport: :lmtp, settings: {
  from_header: "Example <example@example.com>",
  allow_list: ["example.com"]
}
```

With LMTP both the recipient email address and the target LMTP server are provided by the template, inline-encoded in the `to` field as:

```
<email>@<host>:<port>
```

For example a template `to` of `{{user.email}}@mx.internal:24` renders to `user@example.com@mx.internal:24`. The provider uses the email (`user@example.com`) for the `To:` header and the envelope `RCPT TO`, and connects to the LMTP server at `mx.internal:24`. A plain address (without an inline `@host:port`) falls back to the optional `host`/`port` settings.

LMTP templates use the same fields as mail templates (subject, html, layout, tracking). Delivery is synchronous: the server confirms delivery in its reply, so the message is marked `delivered` straight away and no refresh is needed.

### Slack

Slack uses the [postMessage](https://api.slack.com/methods/chat.postMessage) method to send messages. It will also upload any attachment the message has prior to sending the message itself.

The message body is specified using `text` and additionally supports the `payload` parameter.

The payload is merged with the `text`, `to` (channel or user) and `from`.

### Teams

For Microsoft Teams you need to have the webhook URL for a channel. You right-click the channel (not the team) and click "Manage channel". 
Then on the settings click "Edit" under "Manage the connectors that post to this channel", then search for "Incoming Webhook" and add it and configure it.
You can give it a name and an image.

See [Create Incoming Webhooks](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=newteams%2Cdotnet) for details.

### SMS

SMS just support the `from` (name or phone number), `to` (the phone) and `text` attribute.

#### Twilio

#### MessageBird (now Bird)

MessageBird allows for names when sending SMS messages. Messagebird does not support a hypen in the name, just alphabetical characters (A-Za-z).
The MessageBird API we use (REST) is now considered legacy by Bird, new signups are no longer possible. We don't recommend using MessageBird (Bird).

#### smstools

We have support for [smstools](https://www.smstools.nl). smstools supports names when sending SMS messages. 

### Voice

Currently only Twilio voice is supported in the voice transport.

Information on voice TWIML is here: https://www.twilio.com/docs/voice/twiml
You can try voices here: https://www.twilio.com/docs/voice/twiml/say/text-speech

The Voice transport is particularly nice, because you can define whole paths in the message body, for example:

```
<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="en-US">
        Hello Earthling, this is a message from your Robot Overlords!
        <break strength="x-weak" time="100ms"/>
        <p>We will soon give you your escape-hatch-code, so grab a pen and write it down.</p>
    </Say>
    <Gather input="dtmf" numDigits="1" action="{%raw%}{{url}}{%endraw%}/code">
       <Say language="en-US">Press any key to continue.</Say>
    </Gather>
    <Redirect>{%raw%}{{url}}{%endraw%}/code</Redirect>
</Response>

---
path: /code
---
<?xml version="1.0" encoding="UTF-8"?>
<Response>
  <Gather input="dtmf" numDigits="1">
     <Say language="en-US">
      <s>Your code is:</s>
      <break strength="x-weak" time="100ms"/>
      <prosody rate="x-slow"><say-as interpret-as="character">s e n d h e l p</say-as></prosody>
      <break strength="x-weak" time="1s"/>
      Press any key to continue, or just hang up.
     </Say>
  </Gather>
  <Redirect>{%raw%}{{url}}{%endraw%}/code</Redirect>
</Response>
```

### Inbound

Inbound messages are also possible, currently mail/IMAP and Twilio inbound SMS are supported.
This is done using message-boxes, for this to work you need to add a `message_boxes` folder to your `app` folder.

#### SMS

Twilio is currently the only supported inbound SMS provider.
Point Twilio to you nuntius mount path (/messaging/inbound_messages/twilio_inbound_smses)

```ruby
class FooMessageBox < Nuntius::BaseMessageBox
  transport :sms
  provider :twilio

  route /\+31.+/, to: :dutchies
end
```

#### Mail
Nuntius will look at a mailbox and for each of the mails will check whether it can find a route for it in any of the message-boxes. 
After delivery, on the next round of fetching mail, nuntius will move processed message to the Archive folder 

```ruby
class BarMessageBox < Nuntius::BaseMessageBox
  transport :mail
  provider :imap

  settings({
    address: 'imap.gmail.com',
    port: 993,
    user_name: '',
    password: '',
    authentication: '',
    enable_ssl: false,
    enable_starttls: false
  })
  
  route to: :process
  
  def process
    puts message.state # message is Nuntius's inbound message.
    puts mail.to # mail gives you the Mail representation, when it's a mail (transport)
  end
end
```

Add `Nuntius::RetrieveMailJob` to your cron.

## Campaigns

Campaigns allows you to bulk send many mails to subscribers.
We support multiple lists with many subscribers.

Mail campaigns are designed in the email editor, in a layout, like templates (see [Email designs](#email-designs)). When the campaign's list allows unsubscribing, the campaign must contain the Manage subscription block, which links each subscriber to their own page.

A campaign starts as a draft. Scheduling it (the Schedule action in the admin, or `campaign.schedule!`) hands it to `Nuntius::CampaignPublishJob`, which publishes it at its publish time, or when it has none, within a minute (scheduling runs the job a minute later). Add `Nuntius::CampaignPublishJob` to your cron, every minute or so, to publish campaigns at their publish time. Descheduling a campaign (`campaign.deschedule!`) puts it back in draft, so it can be changed.

## Development

Nuntius comes with a devcontainer and a dummy app (in test/dummy) using Satis and Mensa, like a host app would.

```sh
bin/setup        # installs gems, prepares the database and builds the Tailwind CSS
bin/overmind s   # starts the web server and Tailwind watcher (see Procfile), jobs run in-process
```

With OrbStack the dummy app is available on http://app.nuntius.orb.local.

Credentials for the dummy app (e.g. Lettermint) live in test/dummy/config/credentials/development.yml.enc, edit them with
`bin/rails credentials:edit --environment development` from test/dummy (not from the root). The key is not checked in, put it in
test/dummy/config/credentials/development.key or set `RAILS_MASTER_KEY` (e.g. in your mise.toml), which takes precedence.
