# frozen_string_literal: true

# status_mapping = { %w(failed undelivered) => 'failed', 'delivered' => 'delivered'}
#
# puts status_mapping
require 'pp'

# m = Nuntius::Message.create(to: '+31641085630', text: "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - test", transport: 'sms')
# m = Nuntius::Message.create(to: '5c5f8f06e8808bddbd0f7883709a2903124bfe445bcca3807a2997a3480674da', text: "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - test", transport: 'push')

# m = Nuntius::Message.create(to: 'cgLW7RRyqhQ:APA91bHAKexgybHs8ndIFI-OqkB0KjLOJOt_HV3fULF4v2erXT9QiuOstDbf0gHWwgcyKAM1KYuonYdpvokUo2UGVyVxIhoBZRljQZgdSOVmhEdII4zJDgIlPcqvZd_C0NhIJhcxLZOL', text: "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - test", transport: 'push')

m = Nuntius::Message.create(to: 'tom@degrunt.nl', html: '<b>Hoi</b>', text: "#{Time.now.strftime('%Y-%m-%d %H:%M:%S')} - test", transport: 'mail')

# t = Nuntius::TwilioSmsProvider.new()
# t = Nuntius::TwilioSmsProvider.new()

st = Nuntius::MailTransport.new

a = Account.first
Nuntius.with(a).message(:created)

# messenger = AccountMessenger.new(a, 'created', {})
# templates = messenger.call
# messenger.dispatch(templates) if templates
# messenger.call

# pp st.deliver(m)

binding.pry

pp a

# response = t.send(m)
#
# pp response
#
# binding.pry
#
# response = t.refresh(m)
#
# pp response
#
# puts "done!"
#
# Nuntius::Template.where("metadata->>'retailer_id' = '4bfeea93-3b4b-449a-8bdf-01b030219ade'")

# Nuntius.with(shipment: s).message(:picked_up)
#
# class ShipmentMesssenger
#
#   def picked_up(shipment)
#
#     return if shipment.retailer.optoupt
#
#     if shipment.user.no_emails?
#       templates = templates.no(:email)
#     end
#
#     templates.metadata(retailer: shipment.retailer, company: shipment.company)
#   end
#
# end
