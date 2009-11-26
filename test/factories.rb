# -*- coding: utf-8 -*-

Factory.define :country do |f|
  f.name "Deutschland"
  f.code 49
end

Factory.define :address do |a|
  a.salutation "Herr"
  a.company    "Kazik"
  a.fullname   "Test Person"
  a.addition   "Erdgeschoss"
  a.street     "Teststrasse 1337"
  a.zipcode    "10999"
  a.association :country, :factory => :country
end

Factory.define :delivery_address, :parent => :address  do |a|
  a.salutation "Lieferant"
  a.company    "Kazik Lieferant"
  a.fullname   "Test Lieferant"
  a.addition   "6. OG"
  a.street     "Lieferstrasse 1337"
  a.zipcode    "10961"
end

Factory.define :invoice_address, :parent => :address  do |a|
  a.salutation "Rechnungszahler"
  a.addition   "Rechnung"
end

Factory.define :customer do |a|
  a.errors []
  a.warnings []
  a.sequence(:id) {|n| n + 1}
  a.currency_code 1
  a.language_id 0
  a.infoblock   { |i| i.association(:infoblock, :customer_id => i.id )}
  a.association :address, :factory => :invoice_address
  a.association :delivery_address,:factory => :delivery_address
  a.sequence(:order_number) {|n| 1337 + n}
  a.payment_term "Zahlbar per Überweisung innerhalb von 21 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."
  a.payment_mode "0"
  a.payment_code "4"
  a.delivery_term "01 vers. Versand"
  a.shipping_code 1
  a.delivery_terms_code 1
  a.ustid "DE0123456789"
end

Factory.define :infoblock do |a|
  a.editor        '2 FIN'
  a.attachment_no 'Bezugsnummer'
  a.ustidnr       'KD_EG_ID_Nummer'
  a.delivered_at  '02.02.2003'
  a.invoiced_at   '01.02.2003'
  a.state         'Status'
  a.entry         'Händlerlisteneintrag'
  a.segment       'Marktsegment'
  a.fax           '01234 567890'
end

Factory.define :item do |f|
  f.sequence(:id) { |n| n + 9000 }
  f.title { |a| "Item_#{a.id}"}
  f.short_title { |a| "Item_#{a.id}"}
  f.grossprice_1 "19.99"
  f.grossprice_2 "0"
  f.netprice_1   "19.00"
  f.netprice_2   "0"
  f.quantity    1
  f.language_id 0
  f.locked 0
  f.currency "EUR"
  f.dispocode 0
  f.quantity_unit_code 1
  f.item_tax '19.00'
  f.tax_code 1
end


Factory.define :order do |f|
  f.positions []
  f.association :customer, :factory => :customer
  f.association :address, :factory => :invoice_address
  f.association :delivery_address, :factory => :delivery_address
  f.shipping :text => "zzgl. Versandkosten Handel DE", :value => "9,50"
  f.discount "abzgl. 24,00% Gesamtrabatt"
  f.invoice_print_code "1"
  f.additional_text "Nachbemerkungstext steht hier. Und hier. Und auch noch hier. Nachbemerkungstext steht hier. Und hier. Und auch noch hier."
  f.deliverer_id "asdf1123"
end

Factory.define :invoice, :parent => :order do |f|
  f.is_delivery_note false
  f.is_invoice true
  f.sequence(:id) { |n| n }
  f.sequence(:delivery_note_id) { |x| x }
  f.association :delivery_note, :factory=> :delivery_note
end

Factory.define :delivery_note, :parent => :order do |f|
  f.order_confirmation_id "123123"
  f.sequence(:delivery_note_id) { |n| n }
end

