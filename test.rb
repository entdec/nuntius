# status_mapping = { %w(failed undelivered) => 'failed', 'delivered' => 'delivered'}
#
# puts status_mapping
require 'pp'

m = Nuntius::Message.create(to: '+31641085630', text: "#{Time.now.strftime("%Y-%m-%d %H:%M:%S")} - test", transport: 'sms')

t = Nuntius::TwilioSmsProvider.new()

st = Nuntius::SmsTransport.new

pp st.deliver(m)

binding.pry

pp m

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
