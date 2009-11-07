# -*- coding: utf-8 -*-
class Customer
  # mandatory fields for customer.xsd
  attr_accessor :id, :currency_code
  # additional mandatory fields for german business customers
  attr_accessor :delivery_country, :invoice_country, :language_id
  # there are no additional mandatory fields for other customers
  # if there's no address for the customer, the order must have the address
  # if there's only an invoice address, this will be the deliveryaddress
  # If one of the following datafields is missing within the customer:
  #    * terms and methods of payment
  #    * terms and methods of delivery
  # these fields have to be provided within the order.
  attr_accessor :invoice_address, :delivery_address, :invoice_number, :order_number
  attr_accessor :payment_term, :payment_method, :delivery_term, :delivery_method, :inclusive_taxes, :ustid, :tax_number

  # extracts customer data from file
  # for each order only one customer is involved
  # one f3ile may contain several orders
  def initialize(order)
    invoice_address  = Address.new(order.at('Adresse'))
    delivery_address = DeliveryAddress.new(order.at('Lieferadresse'))
    infoblock = Infoblock.new(order.at('Infoblock'))
    self.id               = infoblock.customer_id
    self.currency_code    = 1 # is always in EUR
    self.delivery_country = delivery_address.country
    self.invoice_country  = invoice_address.country
    self.language_id      = 0 # we have only one language code
    self.invoice_address  = invoice_address
    self.delivery_address = delivery_address
    self.payment_term     = extract_payment_term(order)
    self.delivery_term    = nil # gibts nicht
    self.delivery_method  = order.at('Lieferart').innerHTML.strip if order.at('Lieferart')
    self.inclusive_taxes  = 0   # wird unterschieden?
    self.ustid            = infoblock.ustidnr
    self.invoice_number   = extract_invoice_number(order)
    self.order_number     = extract_order_number(order)
    self.tax_number       = infoblock.taxno
  end

  def type
    "Customer"
  end

  def extract_payment_term(order)
    order.at('Zahlungsbedingung').innerHTML.strip if order.at("Zahlungsbedingung")
  end

  def extract_invoice_number(order)
    if order.at('Betreff_NR')
      field = order.at('Betreff_NR').innerHTML.strip
      nr = field.match(/\d+/)
      nr ? nr[0] : nil
    else
      nil
    end
  end

  def extract_order_number(order)
    order.at('Bestellnr').innerHTML.strip if order.at('Bestellnr')
  end

  def is_eu?
    self.invoice_country.eu? and self.delivery_country.eu?
  end

  def is_german?
    self.invoice_country.germany? and  self.delivery_country.germany?
  end

  def has_ustid?
    !(self.ustid == "" or self.ustid == nil)
  end

  def pays_taxes?
    # Privatpersonen im Drittland werden nicht besteuert
    # Bischof-Gross AG = Schweiz, Geschäftskunde, Drittland, steuerfrei ohne ustid.
    return false unless is_eu?
    # German customers pay taxes even as business
    return true  if is_german?
    # Bluecon = Österreich, Geschäftskunde, EU, steuerfrei mit USt. ID Nr.
    return false if has_ustid?
    # not german, has ustid, is european.
    # Kerstin Wagner = Dänemark, Privatkunde, EU steuerpf. da keine ustid. vorhanden
    return true
  end

  def to_xml
    company    = self.invoice_address.company
    salutation = self.invoice_address.salutation
    fullname   = self.invoice_address.fullname
    invoice_addition  = self.invoice_address.addition
    delivery_addition = self.delivery_address.addition
    delivery_address_1 = company ? "Firma #{company}" : salutation
    delivery_address_2 = company ? "Z.Hd. #{fullname}" : fullname
    delivery_address_3 = delivery_addition ? delivery_addition : invoice_addition
    tax_code = self.pays_taxes? ? 0 : 1
    return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Customer.xsd">
<customer>
  <currencyCode>#{self.currency_code}</currencyCode>
  <customerId>#{self.id}</customerId>
  <deliveryAddress1>#{delivery_address_1}</deliveryAddress1>
  <deliveryAddress2>#{delivery_address_2}</deliveryAddress2>
  <deliveryAddress3>#{delivery_address_3}</deliveryAddress3>
  <deliveryCountryCode>#{self.delivery_country.code}</deliveryCountryCode>
  <deliveryPlace>#{self.delivery_address.place}</deliveryPlace>
  <deliveryStreet>#{self.delivery_address.street}</deliveryStreet>
  <deliveryTermsCode>#{delivery_term}</deliveryTermsCode>
  <deliveryZipCode>#{self.delivery_address.zipcode}</deliveryZipCode>
  <grossPriceCode>#{self.inclusive_taxes}</grossPriceCode>
  <invoiceAddress1>#{self.invoice_address.salutation}</invoiceAddress1>
  <invoiceAddress2>#{self.invoice_address.fullname}</invoiceAddress2>
  <invoiceAddress3>#{self.invoice_address.addition}</invoiceAddress3>
  <invoiceCountryCode>#{self.invoice_country.code}</invoiceCountryCode>
  <invoicePlace>#{self.invoice_address.place}</invoicePlace>
  <invoiceStreet>#{self.invoice_address.street}</invoiceStreet>
  <invoiceZipCode>#{self.invoice_address.zipcode}</invoiceZipCode>
  <languageId>#{self.language_id}</languageId>
  <taxNummber>#{self.tax_number}</taxNumber>
  <taxCode>#{tax_code}</taxCode>
  <vatNummber>#{self.ustid}</vatNumber>
  <text1>#{self.order_number}</text1>
  <text2>#{self.invoice_number}</text2>
</customer>
</Root>
XML
  end
end
