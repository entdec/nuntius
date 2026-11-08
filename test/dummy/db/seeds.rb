# frozen_string_literal: true

# Seed data for the dummy app, run with: bin/rails db:seed (from test/dummy). db:prepare (bin/setup) also runs it when
# it creates the database.
# Idempotent, records are only created when missing, so Nuntius events (Account#created, User#create) fire once.

accounts = %w[Acme Globex Initech].to_h do |name|
  [name, Account.find_or_create_by!(name: name)]
end

[
  {name: "Alice Admin", email: "alice@example.com", state: "active", account: "Acme", born_on: Date.new(1990, 4, 7)},
  {name: "Bob Builder", email: "bob@example.com", state: "active", account: "Acme", born_on: Date.new(1985, 11, 20)},
  {name: "Carol Pending", email: "carol@example.com", state: "pending", account: "Globex", born_on: Date.new(2001, 2, 14)},
  {name: "Dave Disabled", email: "dave@example.com", state: "disabled", account: "Initech"}
].each do |attributes|
  User.find_or_create_by!(email: attributes[:email]) do |user|
    user.name = attributes[:name]
    user.state = attributes[:state]
    user.account = accounts.fetch(attributes[:account])
    user.born_on = attributes[:born_on]
  end
end

# The email layout, as the email editor saved it (db/seeds/default_layout.*)
layout = Nuntius::Layout.find_or_create_by!(name: "Default", account: accounts.fetch("Acme")) do |default|
  default.json = JSON.parse(Rails.root.join("db/seeds/default_layout.json").read)
  default.mjml = Rails.root.join("db/seeds/default_layout.mjml").read
end

# An email's own blocks for the layout's Content block, and their MJML as the editor exports them
paragraph = ->(text) { {"type" => "paragraph", "content" => [{"type" => "text", "text" => text}]} }
email_content = lambda do |*paragraphs|
  text = {"id" => "bseedtext", "type" => "text", "attributes" => {"padding" => "10px 25px"},
          "data" => {"content" => {"type" => "doc", "content" => paragraphs.map { |line| paragraph.call(line) }}}, "children" => []}
  column = {"id" => "bseedcolumn", "type" => "column", "attributes" => {}, "data" => {}, "children" => [text]}
  section = {"id" => "bseedsection", "type" => "section", "attributes" => {"padding" => "20px 0px", "background-color" => "#ffffff"}, "data" => {}, "children" => [column]}
  html = paragraphs.map { |line| %(<p style="margin:0">#{ERB::Util.html_escape(line)}</p>) }.join
  mjml = %(\n    <mj-section background-color="#ffffff" padding="20px 0px">\n      <mj-column>\n        <mj-text padding="10px 25px">#{html}</mj-text>\n      </mj-column>\n    </mj-section>\n    )
  [[section], mjml]
end

# Templates for the dummy app's own models only, showing what the template form does: events, time around a
# date, conditions on the Liquid variables, and the transports
rule = ->(variable, operator, value = "") { {"variable" => variable, "operator" => operator, "value" => value} }

[
  {description: "Welcome an activated user", klass: "User", event: "activate",
   to: "{{ user.email }}", text: "Welcome, {{ user.name }}!",
   conditions: {"match" => "all", "rules" => [rule.call("user.email", "isnt_empty")]}},
  {description: "Birthday", klass: "User", event: "before_born_on", interval: "2 days", recurrence: "yearly",
   to: "{{ user.email }}", text: "Happy birthday in two days, {{ user.name }}!",
   conditions: {"match" => "all", "rules" => [rule.call("user.active?", "is", "true")]}},
  {description: "A new account", klass: "Account", event: "created",
   to: "admin@example.com", text: "{{ account.name }} was just created",
   conditions: {"match" => "any", "rules" => [rule.call("account.name", "is", "Acme"), rule.call("account.name", "matches", "corp")]}},
  {description: "Welcome email for a new user", klass: "User", event: "created", transport: "mail",
   to: "{{ user.email }}", subject: "Welcome to {{ user.account.name }}", layout: layout,
   content: email_content.call("Hi {{ user.name }},", "Your account at {{ user.account.name }} is ready.")}
].each do |attributes|
  Nuntius::Template.find_or_create_by!(description: attributes[:description]) do |template|
    content = attributes.delete(:content)
    template.assign_attributes({transport: "sms"}.merge(attributes, account: accounts.fetch("Acme"), enabled: true, auto_description: false))
    template.assign_content(*content) if content
  end
end

puts "Seeded #{Account.count} accounts, #{User.count} users, #{Nuntius::Layout.count} layouts and #{Nuntius::Template.count} templates"
