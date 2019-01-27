# status_mapping = { %w(failed undelivered) => 'failed', 'delivered' => 'delivered'}
#
# puts status_mapping
require 'pp'

m = Nuntius::Message.new(to: '+31641085630', text: 'test')
t = Nuntius::TwilioProvider.new(sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: 'Boxture')
response = t.send(m)

pp response

binding.pry

response = t.refresh(m)

pp response

puts "done!"

Nuntius::Template.where("metadata->>'retailer_id' = '4bfeea93-3b4b-449a-8bdf-01b030219ade'")

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
