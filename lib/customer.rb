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
  attr_accessor :payment_term, :payment_mode, :payment_code
  attr_accessor :delivery_term, :delivery_terms_code, :shipping_code
  attr_accessor :gross_price_code, :ustid
  attr_accessor :errors, :warnings

  def initialize(default = nil)
    self.import(default) if default
  end

  def import(order)
    self.errors           = []
    self.warnings         = []
    self.address          = Address.new(order.at('Adresse'))
    self.infoblock        = Infoblock.new(order.at('Infoblock'))
    self.id               = infoblock.customer_id
    self.payment_term     = Converter.xml_get('Zahlungsbedingung', order)
    self.payment_mode     = Converter.payment_code(self.payment_term)[:payment_mode]
    self.payment_code     = Converter.payment_code(self.payment_term)[:payment_code]
    self.delivery_term    = Converter.xml_get('Lieferart',order)
    self.delivery_terms_code = Converter.delivery_code(self.delivery_term)[:delivery_terms_code]
    self.shipping_code    = Converter.delivery_code(self.delivery_term)[:shipping_code]
    self.gross_price_code = 1   # wird unterschieden?
    self.ustid            = infoblock.ustidnr
    self.order_number     = Converter.xml_get('Bestellnr', order)
  end

  def valid?
    self.errors << "currency_code is invalid" unless self.currency_code
    self.errors << "customer_id is missing"   unless self.id
    self.errors << "address is missing"       unless self.address
    self.errors << "country is missing"       unless self.address && self.address.country
    self.errors << "invoice country code is missing"  unless self.address && self.address.country && self.address.country.code
    self.errors.flatten!
    self.errors.uniq!
    self.errors.empty?
  end

  def clean?
    self.warnings << "invoice address missing"   unless self.address
    self.warnings << "invoice street missing"    unless self.address && self.address.street
    self.warnings << "invoice addition missing"  unless self.address && self.address.addition
    self.warnings << "invoice zipcode missing"   unless self.address && self.address.zipcode
    self.warnings << "invoice place missing"     unless self.address && self.address.place
    self.warnings.flatten!
    self.warnings.uniq!
    self.warnings.empty?
  end

  def delivery_address?
    !!self.delivery_address
  end

  def to_error_log
    return nil if self.errors.empty?
    self.errors.flatten.join("\n")
  end

  def to_warning_log
    return nil if self.warnings.empty?
    self.warnings.flatten.join("\n")
  end

  def type
    "Customer"
  end

  def error_id
    self.id
  end
  # delivery ausserhalb eu ist immer steuerfrei
  def is_eu?
    self.address.country.eu?
  end

  def is_german?
    self.address.country.germany? or (self.delivery_address && self.delivery_address.country.germany?)
  end

  def has_ustid?
    !(self.ustid == "" or self.ustid == nil)
  end

  def pays_taxes?
    # Privatpersonen im Drittland werden nicht besteuert
    # Bischof-Gross AG = Schweiz, Geschäftskunde, Drittland, steuerfrei ohne ustid.
    return false unless is_eu?
    # German customers pay taxes even as business
    return false if has_ustid? && self.address.country.germany? && !(self.delivery_address && self.delivery_address.country.germany?)
    return true  if is_german?
    # Bluecon = Österreich, Geschäftskunde, EU, steuerfrei mit USt. ID Nr.
    return false if has_ustid?
    # not german, has ustid, is european.
    # Kerstin Wagner = Dänemark, Privatkunde, EU steuerpf. da keine ustid. vorhanden
    return true
  end

  # is always in EUR (1)
  def currency_code
    xml_field("currencyCode", 1, false)
  end

  def customer_id
    result = self.id || nil
    if result
      xml_field('customerId', result, false)
    else
      raise_error('Customer id is missing')
    end
  end

  def short_name
    if self.address
      name = self.address.company || self.address.fullname
      name[0..9]
    else
      raise_error("Neither fullname nor company exists")
    end
  end

  def delivery_company?
    self.delivery_address ? self.delivery_address.company : false
  end

  def delivery_company
    self.delivery_company ? self.delivery_address.company : nil
  end

  def invoice_company?
    self.address && self.address.company ? true : false
  end

  def invoice_company
    self.invoice_company? ? self.address.company : nil
  end

  def delivery_salutation
    self.delivery_address ? delivery_address.salutation : nil
  end

  def delivery_address_1
    if delivery_company? || delivery_salutation
      result = delivery_company? ? delivery_company : delivery_salutation
      xml_field('deliveryAddress1', result)
    else
      nil
    end
  end

  def delivery_address_2
    fullname   = self.delivery_address ? self.delivery_address.fullname : nil
    if fullname
      result = fullname
      xml_field('deliveryAddress2', result)
    else
      nil
    end
  end

  def delivery_address_3
    result  = self.delivery_address ? self.delivery_address.addition : nil
    if result
      xml_field('deliveryAddress3', result)
    else
      nil
    end
  end

  def delivery_address_country_code
    result = self.delivery_address &&
      self.delivery_address.country &&
      self.delivery_address.country_code ? self.delivery_address.country.code : nil
    result || self.address.country.code
  end

  def delivery_address_country_code_xml
    result = self.delivery_address_country_code
    if result
      xml_field('deliveryCountryCode', result, false)
    else
      raise_error('No delivery country code exists, even if there is no delivery country this field is mandatory and should default to invoice country code #{invoice_address_country_code}')
    end
  end

  def delivery_place
    result = self.delivery_address ? self.delivery_address.place : nil
    if result
      xml_field('deliveryPlace', result)
    else
      nil
    end
  end

  def delivery_street
    result = delivery_address ? self.delivery_address.street :  nil
    if result
      xml_field('deliveryStreet', result)
    else
      nil
    end
  end

  def delivery_zipcode
    result = self.delivery_address ? self.delivery_address.zipcode : nil
    if result
      raise_error('deliveryZipCode is too long') if result.length > 6
      xml_field('deliveryZipCode', result, true, 6)
    else
      nil
    end
  end

  def delivery_terms_code_xml
    result = self.delivery_terms_code
    if result
      xml_field('deliveryTermsCode',result, false)
    else
      nil
    end
  end

  def gross_price_code_xml
    result = self.gross_price_code
    if result
      xml_field('grossPriceCode', result, false)
    else
      nil
    end
  end

  def invoice_address_1
    result = self.address ? self.address.salutation : nil
    if result
      xml_field('invoiceAddress1', result)
    else
      nil
    end
  end

  def invoice_address_2
    result = self.address ? self.address.fullname : nil
    if result
      xml_field('invoiceAddress2', result)
    else
      nil
    end
  end

  def invoice_address_3
    result = self.address ? self.address.addition : nil
    if result
      xml_field('invoiceAddress3', result)
    else
      nil
    end
  end

  def invoice_address_country_code
    self.address && self.address.country ? self.address.country.code : nil
  end

  def invoice_address_country_code_xml
    result = self.invoice_address_country_code
    if result
      xml_field('invoiceCountryCode', result, false)
    else
      ""
    end
  end

  def invoice_place
    result = self.address ? self.address.place : nil
    if result
      xml_field('invoicePlace', result)
    else
      nil
    end
  end

  def invoice_street
    result = self.address ? self.address.street : nil
    if result
      xml_field('invoiceStreet', result)
    else
      nil
    end
  end

  def invoice_zipcode
    result = self.address ? self.address.zipcode : nil
    if result
      raise_error('invoiceZipCode is too long') if result.length > 6
      xml_field('invoiceZipCode', result, true, 6)
    else
      nil
    end
  end

  def language_id
    xml_field('languageId', 0, false)
  end

  def vat_number
    result = self.ustid || nil
    if result
      raise_error('vatNumber is too long') if result.length > 14
      xml_field('vatNumber', result, true, 14)
    else
      nil
    end
  end

  def text_1
    result = self.order_number
    if result
      xml_field('text1', result, true, 20)
    else
      nil
    end
  end

  def tax_code
    result = self.pays_taxes? ? 0 : 1
    [
     xml_field('taxCode', result, false),
     xml_field('invoiceCode', result, false)
    ].join("\n")
  end

  def credit_worthiness
    xml_field('creditWorthiness', 1, false)
  end

  # maxlength = 0 means no limitation (which is true for numbers only)
  def xml_field(fieldname, content, cdata = true, maxlength = 40)
    if(content.to_s.length > 0)
      entry = if cdata
                "<![CDATA[#{content[0..maxlength-1]}]]>"
              else
                content
              end
      return "<#{fieldname}>#{entry}</#{fieldname}>"
    else
      return nil
    end
  end

  def raise_error(str)
    raise "#{str} for #{self.type} #{error_id}"
  end

  def to_xml
    middle = [
              currency_code,
              customer_id,
              delivery_address_1,
              delivery_address_2,
              delivery_address_3,
              delivery_address_country_code_xml,
              delivery_place,
              delivery_street,
              delivery_zipcode,
              delivery_terms_code_xml,
              gross_price_code_xml,
              invoice_address_1,
              invoice_address_2,
              invoice_address_3,
              invoice_address_country_code_xml,
              invoice_place,
              invoice_street,
              invoice_zipcode,
              language_id,
              tax_code,
              vat_number,
              text_1,
              credit_worthiness
             ].compact.join("\n")

    return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Customer.xsd">
<customer>
  #{middle}
</customer>
</Root>
XML
  end

  def save!
  end
end
