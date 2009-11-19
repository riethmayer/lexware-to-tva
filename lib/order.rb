# -*- encoding: utf-8 -*-
class Order
  attr_accessor :positions, :customer, :order, :address, :delivery_address
  attr_accessor :shipping, :payment_code, :payment_mode, :discount
  attr_accessor :delivery_print_code, :invoice_print_code, :delivery_date, :shipping_code, :delivery_terms_code
  attr_accessor :additional_text, :is_delivery_note, :delivery_note, :is_invoice
  attr_accessor :representative, :order_number, :description, :order_type
  attr_accessor :order_confirmation_id, :delivery_note_id, :id, :deliverer_id

  def initialize(order)
    self.order                      = order
    ## Finde erst mal heraus was ich bin
    # Lieferschein oder Rechnung?
    invoice_or_delivery_note
    self.customer                   = Customer.new(order)
    self.address                    = self.customer.address
    self.additional_text            = Converter.xml_get('Nachbem',order) ## !! 600+ chars
    self.delivery_date = convert_date(Converter.xml_get('Lieferdatum', order))
    self.order_number               = Converter.xml_get('Bestellnr', order)
    self.representative             = Converter.xml_get('Bearbeiter', order)
    self.description                = Converter.xml_get('Auftragsbeschreibung', order)
    self.discount                   = Converter.xml_get('AUFTR_IST_GES_RAB_BETRAG_Text', order)
    extract_deliverer_id
    self.order_type                 = 1 # fix
    self.delivery_print_code        = 1 # always print delivery_note

    get_positions
    update_invoice_print_code
    set_delivery_codes
    set_payment_codes
    set_additional_costs
    extract_discount
  end

  ## Herausfinden ob es sich um ne Rechnung oder nen Lieferschein handelt.
  def invoice_or_delivery_note
    self.is_invoice = extract_invoice_id && extract_reference
    self.is_delivery_note = extract_order_confirmation_id && extract_delivery_note_id
  end

  ### RECHNUNGSFINDUNG
  # handelt es sich um eine Rechnung, dann existiert eine Rechnungsnummer
  def extract_invoice_id
    invoice_id = Converter.xml_get('Betreff_NR', self.order)
    if invoice_id && invoice_id.match(/Rechnung Nr/)
      self.id = invoice_id.match(/\d+/)[0]
    end
  end
  # Eine Rechnung referenziert immer einen Lieferschein!
  def extract_reference
    delivery_note = Converter.xml_get('Bezugsnummer', self.order)
    if delivery_note && delivery_note.match(/Lieferschein/)
      self.delivery_note_id = delivery_note.match(/\d+/)[0]
      return (self.delivery_note_id ? true : false)
    end
  end
  ### RECHNUNGSFINDUNG ENDE

  ### LIEFERSCHEINFINDUNG
  # existierte eine Auftragsbestaetigung, handelt es sich um einen Lieferschein
  def extract_order_confirmation_id
    confirmation = Converter.xml_get('Bezugsnummer', self.order)
    if confirmation && confirmation.match(/Auftragsbest/)
      self.order_confirmation_id = confirmation.match(/\d+/)[0]
      return (self.order_confirmation_id ? true : false)
    end
  end
  # Lieferschein hat seine ID in der Betreff_NR
  def extract_delivery_note_id
    delivery_note = Converter.xml_get('Betreff_NR', self.order)
    if delivery_note && delivery_note.match(/Lieferschein/)
      self.delivery_note_id = delivery_note.match(/\d+/)[0]
      return (self.delivery_note_id ? true : false)
    end
  end
 ### LIEFERSCHEINFINDUNG ende

  # Kundennummer, falls vorhanden
  def extract_deliverer_id
    order_nr = Converter.xml_get('KdNrbeimLief', self.order)
    if order_nr && (match = order_nr.match(/\d+/))
      self.deliverer_id = match[0]
    end
  end
  # Rechnung ins Paketstueck?
  # 0 : nein, 1 : ja, default : ja
  def update_invoice_print_code
    if self.delivery_note && Address.differs?(self.address, self.delivery_note.address)
      self.invoice_print_code = 0
    else
      self.invoice_print_code = 1
    end
  end
  # conversion from comma to point values
  def extract_discount
    discount = self.discount.match(/abzgl. (\d\d),(\d\d)%/)
    self.discount = "#{discount[1]}.#{discount[2]}" if discount
  end
  # extrem wichtig, dass die einzelnen Positionen samt Preis gespeichert werden
  def get_positions
    self.positions = []
    (self.order/:PosNr).each do |position|
      self.positions << Item.new(position)
    end
  end
  # Lieferkosten, Versicherung
  def set_additional_costs
    if Converter.xml_get('Nebenleistungen', self.order)
      self.shipping = {
        :text => Converter.xml_get('Nebenleistungen_Text', self.order),
        :value => Converter.convert_value(Converter.xml_get('Nebenleistungen_Betrag', self.order))
      }
      self.shipping = nil if "#{self.shipping[:text]}#{self.shipping[:value]}" == ""
    else
      self.shipping = nil
    end
  end

  ## DELIVERY AND PAYMENT-CODES
  #
  def set_delivery_codes
    description = Converter.xml_get('Lieferart', self.order)
    if description
      codes = Converter.delivery_code(description)
      self.shipping_code        = codes[:shipping_code] if codes
      self.delivery_terms_code  = codes[:delivery_terms_code] if codes
    end
  end
  def set_payment_codes
    payment = Converter.xml_get('Zahlungsbedingung', self.order)
    if payment
      codes = Converter.payment_code(payment)
      self.payment_code        = codes[:payment_code] if codes
      self.payment_mode        = codes[:payment_mode] if codes
    end
  end
  #
  ## END OF DELIVERY AND PAYMENT-CODES

  def invoice?
    self.is_invoice
  end

  def delivery_note?
    self.is_delivery_note
  end

  def update_fields(delivery_notes)
    delivery_notes.each do |d|
      if (d.delivery_note_id == self.delivery_note_id) && d.delivery_note?
        self.delivery_note = d
        self.delivery_address = d.address
      end
    end
    update_invoice_print_code
  end

  def type
    invoice? ? "Invoice" : "DeliveryNote"
  end

  def add_costs_xml
    if self.add_costs?
      <<-COSTS
<addCosts1>#{self.shipping[:text]}</addCosts1>
<addCostsValue1>#{self.shipping[:value]}</addCostsValue1>
COSTS
    else
      ""
    end
  end

  def discount_xml
    if self.discount
      "<discount1>#{self.discount}</discount1>"
    else
      ""
    end
  end

  def convert_date(date)
    date_match = date.match /(\d\d)\.(\d\d)\.(\d\d\d\d)/
    if date_match && date_match.length == 4
      "#{date_match[3]}-#{date_match[2]}-#{date_match[1]}"
    else
      date
    end
  end

  def urgent?
    self.description.downcase.match(%r{(eilt|eilig|urgent|schnell|asap|immed)})
  end

  def add_costs?
    !!self.shipping
  end

  def xml_for(items)
    xmls = []
    items.each do |item|
      xmls << item.xml_partial
    end
    xmls.join("\n")
  end

  def to_xml
    company    = self.address.company
    salutation = self.address.salutation
    salutation = salutation || self.address.salutation || "Herr/Frau/Firma"
    fullname   = self.address.fullname
    fullname   = fullname || self.address.fullname
    street     = self.address.street
    street     = street || self.address.street
    place      = self.address.place
    place      = place || self.address.place
    country    =  self.address.country.code
    zipcode    = self.address.zipcode
    zipcode    = zipcode || self.address.zipcode
    invoice_addition   = self.address.addition
    delivery_addition  = self.delivery_address.addition if self.delivery_address
    delivery_address_1 = company ? "Firma #{company}" : salutation
    delivery_address_2 = company ? "Z.Hd. #{fullname}" : fullname
    delivery_address_3 = delivery_addition ? delivery_addition : invoice_addition
    delivery_place = place ? place : self.address.place
    country_code   = country ? country : self.address.country
    gross_price_code = self.customer.pays_taxes? ? 1 : 0 # other than customer taxcode
    reference2 = "#{self.order_number} ; #{self.deliverer_id}"[0..39]
    return <<-XML
<?xml version="1.0"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///order.xsd">
  <order>#{add_costs_xml}
    <addText><![CDATA[#{self.additional_text[0..235]}]]></addText>
    <customerId>#{self.customer.id}</customerId>
    <deliveryCountryCode>#{country_code}</deliveryCountryCode>
    <deliveryDate>#{self.delivery_date}</deliveryDate>
    <deliveryName1><![CDATA[#{delivery_address_1[0..39]}]]></deliveryName1>
    <deliveryName2><![CDATA[#{delivery_address_2[0..39]}]]></deliveryName2>
    <deliveryName3><![CDATA[#{delivery_address_3[0..39]}]]></deliveryName3>
    <deliveryPlace><![CDATA[#{place[0..39]}]]</deliveryPlace>
    <deliveryPrintCode>1</deliveryPrintCode>
    <deliveryStreet><![CDATA[#{street[0..39]}]]</deliveryStreet>
    <deliveryTermsCode>#{self.delivery_terms_code}</deliveryTermsCode>
    <deliveryZipCode>#{zipcode}</deliveryZipCode>
    #{discount_xml}
    <grossPriceCode>#{gross_price_code}</grossPriceCode>
    <invoiceCountryCode>#{self.customer.address.country.code}</invoiceCountryCode>
    <invoiceName1><![CDATA[#{self.address.salutation[0..39]}]]></invoiceName1>
    <invoiceName2><![CDATA[#{self.address.fullname[0..39]}]]></invoiceName2>
    <invoiceName3><![CDATA[#{self.address.addition[0..39]}]]></invoiceName3>
    <invoicePlace>#{self.address.place}</invoicePlace>
    <invoicePrintCode>#{self.invoice_print_code}</invoicePrintCode>
    <invoiceStreet><![CDATA[#{self.address.street[0..39]}]]></invoiceStreet>
    <invoiceZipCode>#{self.address.zipcode}</invoiceZipCode>
    <orderType>#{self.order_type}</orderType>
    <paymentCode>#{self.payment_code}</paymentCode>
    <paymentMode>#{self.payment_mode}</paymentMode>
    <reference1>#{self.order_confirmation_id}</reference1>
    <reference2><![CDATA[#{reference2[0..39]}]]></reference2>
    <representative1>#{self.representative}</representative1>
    <shippingCode>#{self.shipping_code}</shippingCode>
    <shortName>#{self.customer.short_name}</shortName>
    <urgentCode>#{self.urgent? ? 1 : 0}</urgentCode>
    <positionen AnzPos="#{positions.length}">

#{xml_for(positions)}

    </positionen>
  </order>
</Root>
XML
  end
end
