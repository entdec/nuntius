# frozen_string_literal: true

# Seed data for the dummy app, run with: bin/rails db:seed (from test/dummy). db:prepare (bin/setup) also runs it when
# it creates the database.
# Idempotent, records are only created when missing, so Nuntius events (Account#created, User#create) fire once.

accounts = %w[Acme Globex Initech].to_h do |name|
  [name, Account.find_or_create_by!(name: name)]
end

[
  {name: "Alice Admin", email: "alice@example.com", state: "active", account: "Acme"},
  {name: "Bob Builder", email: "bob@example.com", state: "active", account: "Acme"},
  {name: "Carol Pending", email: "carol@example.com", state: "pending", account: "Globex"},
  {name: "Dave Disabled", email: "dave@example.com", state: "disabled", account: "Initech"}
].each do |attributes|
  User.find_or_create_by!(email: attributes[:email]) do |user|
    user.name = attributes[:name]
    user.state = attributes[:state]
    user.account = accounts.fetch(attributes[:account])
  end
end

puts "Seeded #{Account.count} accounts and #{User.count} users"
