# Pins for the nuntius gem. The host app imports it with: import "nuntius"

pin "nuntius", to: "nuntius/application.js"
pin_all_from Nuntius::Engine.root.join("app/javascript/nuntius"), under: "nuntius", to: "nuntius"
