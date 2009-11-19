# -*- coding: utf-8 -*-
class Customer
  attr_accessor :id, :currency_code
  attr_accessor :language_id, :infoblock
  # if there's no address for the customer, the order must have the address
  # if there's only an invoice address, this will be the deliveryaddress
  # If one of the following datafields is missing within the customer:
  #    * terms and methods of payment
  #    * terms and methods of delivery
  # these fields have to be provided within the order.
  attr_accessor :address, :delivery_address, :order_number
  attr_accessor :payment_term, :payment_method, :delivery_term, :delivery_method, :inclusive_taxes, :ustid, :tax_number

  def initialize(order)
    self.address          = Address.new(order.at('Adresse'))
    self.delivery_address = DeliveryAddress.new(order.at('Lieferadresse'))
    self.infoblock        = Infoblock.new(order.at('Infoblock'))
    self.id               = infoblock.customer_id
    self.currency_code    = 1 # is always in EUR
    self.language_id      = 0 # we have only one language code
    self.payment_term     = Converter.xml_get('Zahlungsbedingung', order)
    self.delivery_term    = nil # gibts nicht
    self.delivery_method  = Converter.xml_get('Lieferart',order)
    self.inclusive_taxes  = 0   # wird unterschieden?
    self.ustid            = infoblock.ustidnr
    self.order_number     = Converter.xml_get('Bestellnr', order)
    self.tax_number       = infoblock.taxno
  end

  def type
    "Customer"
  end

  # delivery ausserhalb eu ist immer steuerfrei
  def is_eu?
    self.address.country.eu?
  end

  def is_german?
    self.address.country.germany? or (self.delivery_address.country.germany?)
  end

  def has_ustid?
    !(self.ustid == "" or self.ustid == nil)
  end

  def pays_taxes?
    # Privatpersonen im Drittland werden nicht besteuert
    # Bischof-Gross AG = Schweiz, Geschäftskunde, Drittland, steuerfrei ohne ustid.
    return false unless is_eu?
    # German customers pay taxes even as business
    return false if has_ustid? && self.address.country.germany? && !self.delivery_address.country.germany?
    return true  if is_german?
    # Bluecon = Österreich, Geschäftskunde, EU, steuerfrei mit USt. ID Nr.
    return false if has_ustid?
    # not german, has ustid, is european.
    # Kerstin Wagner = Dänemark, Privatkunde, EU steuerpf. da keine ustid. vorhanden
    return true
  end

  def short_name
    name = self.address.fullname || self.address.company
    name.split(' ').last[0..9]
  end

  def to_xml
    company    = self.address.company
    salutation = self.address.salutation || "Frau/Herr/Firma"
    fullname   = self.address.fullname
    invoice_addition   = self.address.addition
    delivery_addition  = self.delivery_address.addition
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
  <deliveryAddress1><![CDATA[#{delivery_address_1[0..39]}]]></deliveryAddress1>
  <deliveryAddress2><![CDATA[#{delivery_address_2[0..39]}]]></deliveryAddress2>
  <deliveryAddress3><![CDATA[#{delivery_address_3[0..39]}]]></deliveryAddress3>
  <deliveryCountryCode>#{self.delivery_address.country.code}</deliveryCountryCode>
  <deliveryPlace>#{self.delivery_address.place}</deliveryPlace>
  <deliveryStreet><![CDATA[#{self.delivery_address.street[0..39]}]]></deliveryStreet>
  <deliveryTermsCode>#{delivery_term}</deliveryTermsCode>
  <deliveryZipCode>#{self.delivery_address.zipcode}</deliveryZipCode>
  <grossPriceCode>#{self.inclusive_taxes}</grossPriceCode>
  <invoiceAddress1><![CDATA[#{self.address.salutation[0..39]}]]></invoiceAddress1>
  <invoiceAddress2><![CDATA[#{self.address.fullname[0..39]}]]></invoiceAddress2>
  <invoiceAddress3><![CDATA[#{self.address.addition[0..39]}]]></invoiceAddress3>
  <invoiceCountryCode>#{self.address.country.code}</invoiceCountryCode>
  <invoicePlace>#{self.address.place}</invoicePlace>
  <invoiceStreet><![CDATA[#{self.address.street}]]></invoiceStreet>
  <invoiceZipCode>#{self.address.zipcode}</invoiceZipCode>
  <languageId>#{self.language_id}</languageId>
  <taxNumber>#{self.tax_number}</taxNumber>
  <taxCode>#{tax_code}</taxCode>
  <vatNumber>#{self.ustid}</vatNumber>
  <text1><![CDATA[#{self.order_number[0..7]}]]></text1>
</customer>
</Root>
XML
  end
end
