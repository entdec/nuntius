# frozen_string_literal: true

account = Account.first

# t = Nuntius::Template.first
# binding.pry

100.times do |i|
  puts i
  Nuntius.with({ 'wms' => {
                 "to": 'tom@boxture.com',
                 "customer_ref": 'SBL1234567',
                 "consignee_name": 'Sander Helsloot',
                 "name": 'Foo',
                 "moo": 'Cow'
               } }, locale: ARGV[0] || 'nl').message(:receiving)
end

# binding.pry

Mail::TestMailer.deliveries.clear
