# Nuntius

Nuntius offers messaging and notifications for ActiveRecord models in Ruby on Rails applications.

## Setup

Add Nuntius to your Gemfile. It brings [TessEdit](https://github.com/tdegrunt/tess_edit), the drag-and-drop editor its email editor is built on, from RubyGems.

```ruby
gem "nuntius"
```

Run bundle install, then copy the migrations and run them:

```sh
bin/rails nuntius:install:migrations
bin/rails db:migrate
```

Nuntius' admin pages need importmap-rails, Propshaft, Tailwind CSS 4 through tailwindcss-rails 4.3 or later (for engine support), [Mensa](https://github.com/entdec/mensa) for their tables, and [FormComponents](https://github.com/entdec/form_components) for their forms, a dependency from GitHub: add `gem "form_components", github: "entdec/form_components"` to your Gemfile. Import Nuntius' JavaScript, which uses your app's Stimulus application (`window.Stimulus`) or starts one, and register FormComponents' controllers with it:

```js
// app/javascript/application.js
import "nuntius"
import { registerFormComponents } from "form_components"

registerFormComponents(window.Stimulus)
```

and add the styles of Nuntius, the email editor, FormComponents and the forms' view components ([entdec-view_components](https://github.com/entdec/view_components), a dependency from GitHub: add `gem "entdec-view_components", github: "entdec/view_components"` to your Gemfile) to your Tailwind CSS:

```css
/* app/assets/tailwind/application.css */
@import "../builds/tailwind/nuntius";
@import "../builds/tailwind/tess_edit";
@import "../builds/tailwind/entdec_view_components";
@import "../builds/tailwind/form_components";
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

A messenger is optional. Without one, `Nuntius::DefaultMessenger` sends the model's templates: on its
state machine's and life cycle's events, around its timestamps, and on demand. Attachments come from the
template itself (see [Attachments](#attachments)), and the account from `config.account_for`.

Define an extension of Nuntius::BaseMessenger for the model with a matching name (in app/messengers) for
events of its own (a method each), extra parameters, or to manipulate the templates selected:

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

### Triggers

Templates are sent on a trigger of their object, named for what it is or what happened to it:

- with the state_machines-activemodel gem, `nuntiable use_state_machine: true`: each state its events
  go to. A template for Order on `shipped` is sent when an order goes to shipped, whichever event took
  it there, once the transaction commits. A transition that stays in its state sends nothing;
- `nuntiable life_cycle: true`: `created`, `updated`, `saved` (either) and `destroyed`;
- its own, fired by name (see [With templates](#with-templates)), declared so templates can choose them:
  `nuntiable triggers: %i[reminded]`, or by a messenger's methods;
- before and after its dates and times (see [Timebased events](#timebased-events)).

Name your own for what happened, as the states are: `reminded`, not `remind`.

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

**The admin** shows, creates and changes the `visible` records only: other accounts' records give a 404. New records get the current account. A template's layout, and a campaign's list and layout, must belong to its own account. The template form has a Global check box when `config.can_create_global` allows it.

### Admin pages

Each admin page is drawn by a frame, a partial in `nuntius/admin/shared`, which your app can have itself to show the pages in its own look: copy Nuntius' to `app/views/nuntius/admin/shared/` in your app and change it. The pages give the frames what's on them; the frames decide how it looks.

- `_index`, an index page: `name` (the page's, as `nuntius_admin_templates`), `title`, `icon` and `actions`. The block (`yield`) is its table.
- `_page`, a record's page: `name`, `title` (a text, or HTML: the field that edits a template's description in place), `icon`, `form` (the builder of the page's form, nil for a page that isn't one), `actions`, `back` (where a new record's page goes back to, or nil), `tabs` (`Nuntius::Page::Tab`s, with `id`, `label`, `padding` and `content`: `padding` is false for a tab its content fills, an editor or a table), `aside` (what's about the record, a message's state or a list's settings, shown beside the tabs whichever is open, or nil) and `body` (the content of a page without tabs). Save submits the page's form and keeps the user on the record's page; when it doesn't save, the page shows the form again with why (`.nuntius-page__errors`, from the form's object).
- `_page_action`, one of the actions, a `Nuntius::PageAction`: `id`, `label`, `link` and `icon`, with `method` (a request other than GET, through Turbo's `data-turbo-method`) and `confirm`, or `submit` (Send test, Import: it sends the page's form to `link` instead). A `submit` action has to be a button inside the form, with `formaction`; a frame that shows the actions outside the form keeps a hidden button there and clicks it.
- `_attachments`, a Media tab: `form`, `attribute` (`images` or `attachments`) and `delete`, a proc giving an attachment's delete path.

Nuntius' own frames are styled by its `nuntius-*` classes; yours don't need them. Their icons are Font Awesome's (which your app loads), by what they're for: Font Awesome Free's by default. With Font Awesome Pro, set `config.icons = Nuntius::Configuration::PRO_ICONS`, or merge your own in: `config.icons = Nuntius::Configuration::FREE_ICONS.merge(template: "fa-solid fa-envelope")`.

### Your app's part

Nuntius brings as little as it can: no authentication, roles or notifications. Your app adds what it needs.

**Authentication.** The admin pages have none of their own: anyone who can reach where you mounted Nuntius can use them, until you set `config.admin_authentication_module` to a concern of your app's. The admin controllers, and the email editor's compile endpoint, include it:

```ruby
# app/controllers/concerns/nuntius_admin_authenticated.rb
module NuntiusAdminAuthenticated
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action { head :forbidden unless current_user.admin? }
  end
end

Nuntius.setup do |config|
  config.admin_authentication_module = "NuntiusAdminAuthenticated"
end
```

The tables on the admin pages are [Mensa](https://github.com/entdec/mensa)'s, whose rows, filters and exports Mensa serves where your app mounted it, so neither the concern nor a guarded mount covers them. Each answers `readable?` from `config.tables_readable` (default: anyone), for your app to ask before Mensa serves a table:

```ruby
Nuntius.setup do |config|
  config.tables_readable = -> { Current.user&.admin? }
end
```

Or guard the mount in your routes, e.g. with Devise: `authenticate(:user, ->(user) { user.admin? }) { mount Nuntius::Engine, at: "/messaging", as: "nuntius" }`. Don't authenticate in `config.base_controller` (default `"::ApplicationController"`): every Nuntius controller inherits from it, also the public ones (subscription pages, tracking, webhooks and callbacks).

**Layouts.** The admin pages render in `config.admin_layout`, the other pages in `config.layout`, both your app's (default `"application"`); the public subscription pages have Nuntius' own `empty` layout.

**Messages.** Saving says nothing: the page stays, or shows why it didn't save. What an action did (a test sent, a message resent, an import queued, a template converted, a subscription changed) is in the flash, as `notice` or `alert`, which your admin layout shows: as text, or through your app's own notifications. An import's result comes later, from a job, as an `import_subscribers.nuntius` event, for your app to tell the user who started it:

```ruby
# config/initializers/nuntius.rb
ActiveSupport::Notifications.subscribe("import_subscribers.nuntius") do |event|
  # list, user, text (what to tell them), and imported and failed, or error when the CSV isn't valid
  result = event.payload
  Signum.send(result[:error] ? :error : :success, result[:user], text: result[:text])
end
```

**Importing subscribers.** A list's page has an Import of subscribers from a CSV. An app with its own import turns Nuntius' off with `config.subscribers_import = false`, which takes away the action and its page, and adds its own action to the list's page (see [Admin pages](#admin-pages)), creating subscribers with `list.subscribers.create(...)`.

**More.** To add to every admin page's controller, include your own concern in Nuntius' when your app loads:

```ruby
# config/initializers/nuntius.rb
Rails.application.config.to_prepare do
  Nuntius::ApplicationAdminController.include(NuntiusAdminAdditions)
end
```

How the pages look is your app's too, see [Admin pages](#admin-pages).

## Usage

### With templates

States and the life cycle send their templates themselves. A trigger of the object's own is fired by name:

```ruby
Nuntius.fire(:reminded, car)
```

When custom events are enabled you can also do the following:

```ruby
Nuntius.fire(:shipped, {shipped: {to: "test@example.com", ref: "Test-123"}}, attachments: [{url: "https://example.com"}])
```

`Nuntius.event` is deprecated: it fires a state machine event as the one state it goes to (`ship` as
`shipped`), and fails for one that goes to several states or stays where it is; Nuntius 1's life cycle
events (`create`) by their names now (`created`).

For the above cases you need to define templates, this is done with the maintenace pages under
/messaging/admin/templates (/messaging is whatever you have defined in your routes file).

When a trigger is fired a message is sent for every matching template of the account it's sent for (see
[Accounts](#accounts)). To send different messages under different circumstances you can specify a
template_scope on the messenger class, a scope on the templates given the nuntiable object, that
narrows down which templates are used:

```ruby
class CarMessenger < Nuntius::BaseMessenger
  template_scope ->(car) { where(transport: car.owner.prefers_sms? ? "sms" : "mail") }
end
```

### Addressees

A template sends a message to each addressee in its To, rendered for that addressee, who the template's Liquid can use as `to`. A To of addresses separated by commas sends a message to each, with the address as `to`. A To of a single variable can also give drops (or hashes), or a list of them, like `{{ order.contacts }}`: each gets its own message, at its `email` for mail, or its `phone_number` for SMS and voice, and is the message's `to`, so a template can greet each one:

```liquid
Dear {{ to.name }},
```

Drops without an address for the transport are left out.

### Naming triggers

The template form reads as a sentence: *Send via [Email] based on [a trigger] on [Order] [shipped]*,
or based on [a time] (see [Timebased events](#timebased-events)). The object is
its model's `model_name.human`, the transports are in alphabetical order (new templates send by mail),
and a trigger's name comes from the first of:

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
           reminded: herinnerd
           after_shipped: na verzending
   ```

3. the state's own name, `activerecord.state_machines.<model>.states.<state>` (from state_machines'
   translations), for `nuntiable use_state_machine: true`; the life cycle's, `nuntius.life_cycle.<created>`;
4. the trigger itself, `after shipped`.

Name a trigger for how it reads after the object: "on Order *shipped*". The transports' names are
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

### On demand

A template can also be sent on demand: neither by an event nor by a time, but by your app, when
someone asks for it, like a message to the contacts someone picked. Its form reads *Send via
[Email] [on demand] for [Contact]*, and it gets the event `on_demand`. Your app offers these
templates (`Nuntius::Template.on_demand`, with the class it sends for) and sends the chosen one:

```ruby
messages = template.deliver_to(contact)
```

That goes through the object's messenger as an event would, with the template's conditions and
its To, open and link tracking. It returns the messages it sent: none when its conditions aren't
met or its To renders empty, like a contact without an email address.

Your app can say whom it goes to and from whom, in place of the template's own To and From and
in the same forms (addresses, drops, lists of them), and leave the template's conditions out,
when something else decides whether it's sent, like an automation's steps:

```ruby
template.deliver_to(contract, to: "{{ contract.contact }}, board@example.com", from: "sponsors@example.com", conditions: false)
```

So one template can go to others from different places. Without them, it's sent as above.

A message says what sent it with `campaign?`, or `on_demand?`, `event_based?` and `time_based?`
from its template as it is now, so a provider's settings can send them through another server:

```ruby
config.provider :smtp, transport: :mail, settings: lambda { |message|
  (message.campaign? || message.on_demand?) ? bulk_settings : outbound_settings
}
```

### Conditions

A template or campaign can send only when its conditions are met: *If [all] of the following conditions are met: [Screening › Payment needed?] [is] [true]*. Instead of a Liquid `if` around the recipient,

```liquid
{% if screening.payment_needed? %}{{ screening.screening_profile.contact.email }}{% endif %}
```

the template's To is `{{ screening.screening_profile.contact.email }}` with that condition. When they aren't met there's no message.

A condition is one of the Liquid variables the template or campaign renders with (see [Variables](#variables)), compared with *is*, *isn't*, *contains*, *doesn't contain*, *is more than*, *is at least*, *is less than*, *is at most*, *is between*, *is empty* or *isn't empty*: text ignoring case, numbers as numbers, dates and times as dates and times, and true or false as *true*, *yes* or *1*. A list *is* or *contains* a value when one of its elements does. The admin offers the operators for the variable's type, and a variable ending in `?` is true or false.

The form chooses the variables with Liquidum's endpoint, so your app needs to mount it (see [Variables](#variables)); without it they're typed in, like `screening.payment_needed?`. They're stored in a `conditions` column (`{"match" => "all", "rules" => [{"variable", "operator", "value", "value_to"}]}`): copy in the migration with `bin/rails nuntius:install:migrations`. A campaign checks its conditions for each subscriber, with `campaign`, `subscriber` and the subscriber's object.

They're checked by Liquidum (`Liquidum::Conditions`, which `Nuntius::Conditions` is), whose JavaScript checks them the same way in the browser.

### Locales

Translate in a template or campaign with Liquidum's `t` filter. Its translations are the locales of its account: add a locale in the admin for each language, with the language as its top key:

```yaml
en:
  greeting: "Hello %{name}"
  signature: "Kind regards"
```

```liquid
{{ 'greeting' | t: name: user.name }}
{{ 'greeting' | t: name: user.name, locale: 'nl' }}
```

A template uses the locales of its own account, so a global template uses its owner's; what they don't have comes from your app's own translations. The message's language is its messenger's `locale` (`locale ->(user) { user.locale }`), or the event's `locale:`.

A key that starts with a dot is looked up in the template's scope first, then towards the root, so one template can have its own version of a translation. The scope is the template's layout, class, event, transport and description, like `default.user.created.mail.welcome_email_for_a_new_user`, so `{{ '.greeting' | t }}` uses `default.user.created.mail.welcome_email_for_a_new_user.greeting`, then `default.user.created.mail.greeting`, and so on up to `greeting`. A campaign's scope, and a layout's, is the layout's name (`default`), so a layout's keys work in its templates and campaigns too. Changing a template's layout, class, event, transport or description (also when Auto makes it, or converting it to a new layout) changes its scope, and the translations in its old scope move along, in every locale of its account; ones already in the new scope stay. Renaming a layout moves the translations in its scope the same way. A global template's translations are in other accounts' locales too, and stay behind.

If an account has several locales for a language, they're merged in the order they were created, later ones winning.

In the email editor a `{{ '.greeting' | t }}` shows as its text, in the language chosen in the editor's top bar ("Keys" shows the Liquid). Pointing at one lists every language's text, missing ones marked, each editable there, with a link to the locale it's in. Make translatable, in the text toolbar and next to the subject, preview text, button labels and other text settings, keeps the selected text (or the setting's) under a key you choose, in the chosen language, and puts the `t` filter in its place; typing `{{ '` suggests the keys. Variables in the selected text become placeholders, given as the filter's arguments: "Hi {{ user.first_name }}" is kept as `Hi %{first_name}`, in `{{ '.hi' | t: first_name: user.first_name }}`. Liquid tags and filters can't go into a translation. A placeholder the filter has no argument for is marked. The Translations tab of a template, campaign or layout lists its keys with their texts in each language, editable too. A text is saved where it's defined; a new one next to its other languages, or else in the template's scope, in the account's locale named after the language (made when there's none). Emptying a text removes it.

Nuntius gives Liquidum (1.4 or later) the translations; configure it in your app:

```ruby
# config/initializers/liquidum.rb
Liquidum.setup do |config|
  config.i18n_store = ->(context) { Nuntius::I18nStore.backend(context) }
  config.translation_scope = ->(context) { Nuntius::I18nStore.translation_scope(context) }
end
```

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
Nuntius.fire(:packed, packing: {smurrefluts: "hatseflats"})
```

The main key of the hash passed will also be the liquid variable.

## Email designs

Mail templates and campaigns are designed in an email editor: Nuntius' email kit for [TessEdit](https://github.com/tdegrunt/tess_edit) (`app/javascript/nuntius/email`), which builds [MJML](https://mjml.io); Nuntius compiles it to HTML with [MRML](https://github.com/jdrouet/mrml) (`Nuntius::Mjml`), which TessEdit's compile endpoint uses too, as its `mjml` compiler. Liquid works everywhere in the design and is rendered when a message is sent.

### Layouts

A layout is the part every email shares: header, footer, width, fonts, colors and CSS. It has exactly one **Content** block, where each template or campaign puts its own content. A new layout starts from one of the starting layouts Nuntius ships: Basic, Newsletter, Transactional or Empty.

Templates and campaigns follow their layout: when you change a layout, every template and draft campaign that uses it is put together again with the new layout. In their editor the layout's parts are visible but locked; only the Content block, the subject and the preview text are theirs.

The email kit has TessEdit's blocks (Section, Column, Text, Image, Button, Divider, Spacer, HTML, Loop, Condition, Assign, Table), with their MJML, and blocks of its own: the Email itself, Wrapper, Hero, Social and Navbar, and three for Nuntius:

- **Content**, the template's or campaign's own part of the layout
- **View in browser**, a link to the message online (`{{ message_url }}`)
- **Manage subscription**, a link to the subscriber's page for the campaign's list (`{{ subscriber_url }}`). Campaigns to a list that allows unsubscribing must contain it.

### Templates and campaigns

A new template starts with what it sends: Email, SMS, Push and so on, as cards, one for each enabled transport. That stays as it's chosen. An email then starts from a layout, chosen by its preview, name and description (give layouts a description that says what they're for). A card opens the template's editor, and it's created when it's saved. The email starts with the layout's example content, and everything about it is in its editor: with the email selected, Inspect has when it sends (the sentence and conditions, collapsed to *Account · created* until you edit them), its From and To, its subject and preview text, its tracking and its layout. Choosing another layout there moves the content into it when it's saved. Its description is the page's title, made from when it sends while Auto is checked, and Enabled is beside it (and under when it sends). SMS, Push, Teams, Slack and Voice templates are edited the same way, with a preview of the message in the middle: an SMS on a phone with its length and number of parts, a push notification on a lock screen, Teams' card and Slack's blocks as JSON (with links to the Adaptive Cards Designer and Block Kit Builder), and Voice's TwiML per path. The preview renders the Liquid with sample values, each variable showing as its name (‹User › Name›), never with someone's data. Only emails on an old layout, or without one, keep the Edit tab.

Every new mail template and campaign needs a layout. A campaign's layout is chosen on its Edit tab; save, and the email is edited on the Design tab.

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

### Attachments

An email attaches files with an **Attachment** block: a file on the web (an https address), or what a
variable gives, picked with the variable menu. It renders as the `attach` tag, which you can also write
yourself, and shows nothing in the email:

```liquid
{% attach 'https://example.com/terms.pdf' %}
{% attach order.label convert:'pdf' %}
{% attach contract.pdf %}
{% attach invoice.documents %}
```

A variable can give a stored file (Active Storage, one or many), or what a drop makes, a hash of `content`
(a string or an IO), `filename` and `content_type`, or a list of those; nothing attaches nothing:

```ruby
class ContractDrop < ApplicationDrop
  def pdf = {content: @object.to_pdf, filename: "contract.pdf", content_type: "application/pdf"}
end
```

A URL is fetched over http(s) only, never as a file of the server (`file://`): a template's text is written in
the admin.

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

Outbound mail is handled through SMTP (the `:smtp` provider on the `:mail` transport), and mail to a mailbox through LMTP (the `:lmtp` provider, see below). Mail is designed in the email editor (see [Email designs](#email-designs)); the text version is made from the HTML.

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

LMTP (RFC 2033) delivers a message directly to a mailbox. It's a provider on the `:mail` transport, next to SMTP:

```ruby
config.provider :lmtp, transport: :mail, settings: {
  from_header: "Example <example@example.com>",
  allow_list: ["example.com"]
}
```

Mail to an LMTP address goes to it, other mail to SMTP. An LMTP address has the recipient's email and the LMTP server to deliver it to:

```
<email>@<host>:<port>
```

For example a template `to` of `{{user.email}}@mx.internal:24` renders to `user@example.com@mx.internal:24`. The provider uses the email (`user@example.com`) for the `To:` header and the envelope `RCPT TO`, and connects to the LMTP server at `mx.internal:24`.

Delivery is synchronous: the server confirms delivery in its reply, so the message is marked `delivered` straight away and no refresh is needed.

A transport only gives a message to the providers that handle its address (`handles?` on the provider class), so SMTP never gets an LMTP address and LMTP never gets a plain one. In the same way APNs gets APNs device tokens and Firebase the other push tokens.

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
Nuntius fetches the mail of each mailbox of the mail message boxes, and delivers each mail to the message box that fetched it, to its route for it.
After delivery, on the next round of fetching mail, nuntius will move processed message to the Archive folder.

A message box has one or more mailboxes, each by a name and its settings: with `mailbox`, once for each.

```ruby
class BarMessageBox < Nuntius::BaseMessageBox
  transport :mail
  provider :imap

  mailbox :orders, {
    address: 'imap.gmail.com',
    port: 993,
    user_name: 'orders@example.com',
    password: ENV['ORDERS_PASSWORD'],
    enable_ssl: true
  }
  mailbox :returns, {address: 'imap.gmail.com', port: 993, user_name: 'returns@example.com', password: ENV['RETURNS_PASSWORD'], enable_ssl: true}

  route :to, /.+/, to: :process

  def process
    puts message.state # message is Nuntius's inbound message.
    puts mail.to # mail gives you the Mail representation, when it's a mail (transport)
    puts mailbox # the name of the mailbox it came from: "orders" or "returns"
  end
end
```

Or with `mailboxes`, from the app's data: its block gives pairs of a name and settings, and is called each time mail is fetched.

```ruby
  mailboxes { Inbox.active.map { |inbox| [inbox.id, inbox.imap_settings] } }
```

The same mail in two mailboxes is two inbound messages, each with its `message_box` and `mailbox`. `settings` (one mailbox) still works, deprecated: it's `mailbox :default`.

A mailbox that can't be fetched (it can't connect or sign in, say) is reported through `Rails.error`, and the other mailboxes are still fetched. With `fetched`, a message box hears how each fetch went: its block gets the mailbox's name, and the error when it couldn't be fetched (nil when it was), to show whether a mailbox works.

```ruby
  fetched { |mailbox, error| Inbox.find_by(id: mailbox)&.update(fetched_at: Time.current, fetch_error: error&.message) }
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

## Backlog

- Machine translation in the email editor: fill a missing language from another one with DeepL or an LLM, as a suggestion to accept, keeping the placeholders.
- A translation block in the email editor: a block whose text is a translation key, edited per language in its settings, instead of selecting text and making it translatable.
- A unique database index on a locale's account and key, now that the model validates it. Existing duplicates need merging first.
