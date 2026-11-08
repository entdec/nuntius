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

# Templates for the dummy app's own models only, showing what the template form does: events, time around a
# date, and conditions on the Liquid variables
rule = ->(variable, operator, value = "") { {"variable" => variable, "operator" => operator, "value" => value} }

[
  {description: "Welcome an activated user", klass: "User", event: "activate",
   to: "{{ user.email }}", text: "Welcome, {{ user.name }}!",
   conditions: {"match" => "all", "rules" => [rule.("user.email", "isnt_empty")]}},
  {description: "Birthday", klass: "User", event: "before_born_on", interval: "2 days", recurrence: "yearly",
   to: "{{ user.email }}", text: "Happy birthday in two days, {{ user.name }}!",
   conditions: {"match" => "all", "rules" => [rule.("user.active?", "is", "true")]}},
  {description: "A new account", klass: "Account", event: "created",
   to: "admin@example.com", text: "{{ account.name }} was just created",
   conditions: {"match" => "any", "rules" => [rule.("account.name", "is", "Acme"), rule.("account.name", "matches", "corp")]}}
].each do |attributes|
  Nuntius::Template.find_or_create_by!(description: attributes[:description]) do |template|
    template.assign_attributes(attributes.merge(transport: "sms", account: accounts.fetch("Acme"), enabled: true, auto_description: false))
  end
end

puts "Seeded #{Account.count} accounts, #{User.count} users and #{Nuntius::Template.count} templates"
