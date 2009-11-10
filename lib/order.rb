class Order
  attr_accessor :id, :positions, :customer, :id, :order
  attr_accessor :shipping, :payment_code, :payment_mode, :discount
  attr_accessor :delivery_print_code, :invoice_print_code, :delivery_date, :shipping_code, :delivery_terms_code
  attr_accessor :additional_text, :delivery_note_id
  attr_accessor :representative, :order_number, :description, :order_type

  def initialize(order)
    self.order                      = order
    self.customer                   = Customer.new(order)
    self.additional_text            = Converter.xml_get('Nachbem',order) ## !! 600+ chars
    self.delivery_date = convert_date(Converter.xml_get('Lieferdatum', order))
    self.order_number               = Converter.xml_get('Bestellnr', order)
    self.representative             = Converter.xml_get('Bearbeiter', order)
    self.description                = Converter.xml_get('Auftragsbeschreibung', order)
    self.discount                   = Converter.xml_get('AUFTR_IST_GES_RAB_BETRAG_Text', order)
    self.payment_mode               = 0 # ???
    self.payment_code               = 0 # ???
    self.order_type                 = 0 # ???
    self.positions                  = positions_for(order)
    self.delivery_print_code        = 1 # always print delivery_note

    extract_ids
    update_invoice_print_code
    extract_delivery_terms_code_from(order)
    set_additional_costs_from(order) # freightage, shipping, insurance
    extract_discount
  end

  def extract_ids
    field = Converter.xml_get('Betreff_NR', self.order)
    value = field.match(/(\d+)/)[1]
    if field.downcase.match(/rechnung/)
      self.id = value
      bezug = Converter.xml_get('Bezug', self.order)
      bezug_value = bezug.match(/zu Lieferschein Nr. (\d+)/) if bezug
      self.delivery_note_id = bezug_value[1] if bezug_value
    else
      self.delivery_note_id = value
    end
  end

  def update_invoice_print_code
    if Address.differs?(self.customer.invoice_address, self.customer.delivery_address)
      self.invoice_print_code = 0
    else
      self.invoice_print_code = 1
    end
  end

  def extract_discount
    discount = self.discount.match(/abzgl. (\d\d),(\d\d)%/)
    self.discount = "#{discount[1]}.#{discount[2]}" if discount
  end

  def positions_for(order)
    positions = []
    (order/:PosNr).each do |position|
      positions << Item.new(position)
    end
    positions
  end

  def set_additional_costs_from(order)
    if Converter.xml_get('Nebenleistungen', order)
      self.shipping = {
        :text => Converter.xml_get('Nebenleistungen_Text', order),
        :value => Converter.convert_value(Converter.xml_get('Nebenleistungen_Betrag', order))
      }
      self.shipping = nil if "#{self.shipping[:text]}#{self.shipping[:value]}" == ""
    else
      self.shipping = nil
    end
  end

  def extract_delivery_terms_code_from(order)
    description, deliver_mode = Converter.xml_get('Lieferart', order).split(';')
    self.shipping_code        = extract_delivery_from(description.strip) if description
    self.delivery_terms_code  = deliver_mode.strip if deliver_mode
  end

  def extract_delivery_from(description)
    shipping_codes = {
      'Lieferung per DHL' => 10001,
      'Selbstabholer'     => 90001,
      'Lieferung per DPD' => 20008,
      'Lieferung frei Haus' => 10099,
      'EXW Berlin Incoterms' => 91006
    }
    shipping_codes[description] || description
  end

  def invoice?
    relation = Converter.xml_get('Betreff_NR', self.order)
    !!relation.downcase.match(/rechnung/)
  end

  def delivery_note?
    relation = Converter.xml_get('Betreff_NR', self.order)
    !!relation.downcase.match(/lieferschein/)
  end

  def update_fields(delivery_notes)
    delivery_notes.each do |delivery_note|
      self.customer = delivery_note.customer if delivery_note.id == self.delivery_note_id
    end
    update_invoice_print_code
  end

  def type
    "Order"
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
    if date_match.length == 4
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
    # items = items.sort_by{ |item| item.position_number }
    items.each do |item|
      xmls << item.xml_partial
    end
    xmls.join("\n")
  end

  def to_xml
    company    = self.customer.invoice_address.company
    salutation = self.customer.invoice_address.salutation
    fullname   = self.customer.invoice_address.fullname
    invoice_addition   = self.customer.invoice_address.addition
    delivery_addition  = self.customer.delivery_address.addition
    delivery_address_1 = company ? "Firma #{company}" : salutation
    delivery_address_2 = company ? "Z.Hd. #{fullname}" : fullname
    delivery_address_3 = delivery_addition ? delivery_addition : invoice_addition
    gross_price_code = self.customer.pays_taxes? ? 1 : 0 # other than customer taxcode
    order_type = 1 # doesn't apply to us
    return <<-XML
<?xml version="1.0"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///order.xsd">
  <order>#{add_costs_xml}
    <addText>#{self.additional_text}</addText>
    <customerId>#{self.customer.id}</customerId>
    <deliveryCountryCode>#{self.customer.delivery_address.country.code}</deliveryCountryCode>
    <deliveryDate>#{self.delivery_date}</deliveryDate>
    <deliveryName1>#{delivery_address_1}</deliveryName1>
    <deliveryName2>#{delivery_address_2}</deliveryName2>
    <deliveryName3>#{delivery_address_3}</deliveryName3>
    <deliveryPlace>#{self.customer.delivery_address.place}</deliveryPlace>
    <deliveryPrintCode>1</deliveryPrintCode>
    <deliveryStreet>#{self.customer.delivery_address.street}</deliveryStreet>
    <deliveryTermsCode>#{self.delivery_terms_code}</deliveryTermsCode>
    <deliveryZipCode>#{self.customer.delivery_address.zipcode}</deliveryZipCode>
    #{discount_xml}
    <grossPriceCode>#{gross_price_code}</grossPriceCode>
    <invoiceCountryCode>#{self.customer.invoice_address.country.code}</invoiceCountryCode>
    <invoiceName1>#{self.customer.invoice_address.salutation}</invoiceName1>
    <invoiceName2>#{self.customer.invoice_address.fullname}</invoiceName2>
    <invoiceName3>#{self.customer.invoice_address.addition}</invoiceName3>
    <invoicePlace>#{self.customer.invoice_address.place}</invoicePlace>
    <invoicePrintCode>#{self.invoice_print_code}</invoicePrintCode>
    <invoiceStreet>#{self.customer.invoice_address.street}</invoiceStreet>
    <invoiceZipCode>#{self.customer.invoice_address.zipcode}</invoiceZipCode>
    <orderType>#{order_type}</orderType>
    <paymentCode>#{self.payment_code}</paymentCode>
    <paymentMode>#{self.payment_mode}</paymentMode>
    <reference1>#{self.order_number}</reference1>
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
