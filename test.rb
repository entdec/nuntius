t = Nuntius::TwilioDriver.new({ sid: 'AC92bf1782ac7790aa62d13f2135a887aa', auth_token: '811738b3a314daa224ce55ca400a97c2', from: 'Boxture' })
response = t.send('+31641085630', 'test')

binding.pry

puts response
