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
  attr_accessor :payment_term, :payment_method, :delivery_term, :delivery_method
  attr_accessor :inclusive_taxes, :ustid
  attr_accessor :errors, :warnings

  def initialize(order)
    self.errors           = []
    self.warnings         = []
    self.address          = Address.new(order.at('Adresse'))
    self.delivery_address = order.at('Lieferadresse')
    self.delivery_address = DeliveryAddress.new(self.delivery_address) if delivery_address?
    self.infoblock        = Infoblock.new(order.at('Infoblock'))
    self.id               = infoblock.customer_id
    self.payment_term     = Converter.xml_get('Zahlungsbedingung', order)
    deliver               = Converter.xml_get('Lieferart',order)
    self.delivery_term    = Converter.delivery_code(deliver)[:delivery_terms_code]
    self.delivery_method  = Converter.delivery_code(deliver)[:shipping_code]
    self.inclusive_taxes  = 0   # wird unterschieden?
    self.ustid            = infoblock.ustidnr
    self.order_number     = Converter.xml_get('Bestellnr', order)
  end

  def valid?
    self.errors << "currency_code is invalid" unless self.currency_code
    self.errors << "customer_id is missing"   unless self.id
    self.errors << "address is missing"       unless self.address
    self.errors << "country is missing"       unless self.address && self.address.country
    self.errors << "deliverycountry code is missing"  unless self.delivery_address && self.delivery_address.country && self.delivery_address.country.code
    self.errors << "invoice country code is missing"  unless self.address && self.address.country && self.address.country.code
    self.errors.flatten!
    self.errors.uniq!
    self.errors.empty?
  end

  def clean?
    self.warnings << "delivery address missing"  unless self.delivery_address
    self.warnings << "delivery street missing"   unless self.delivery_address && self.delivery_address.street
    self.warnings << "delivery addition missing" unless self.delivery_address && self.delivery_address.addition
    self.warnings << "delivery zipcode missing"  unless self.delivery_address && self.delivery_address.zipcode
    self.warnings << "delivery place missing"    unless self.delivery_address && self.delivery_address.place
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
    self.delivery_address.to_s.downcase =~ /[a-z]/
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
      name = self.address.fullname || self.address.company
      name.split(' ').last[0..9]
    else
      raise_error("Neither fullname nor company exists")
    end
  end

  def company?
    self.company
  end

  def company
    return self.address.company if self.address
    nil
  end

  def salutation
    self.address.salutation || "Frau/Herr/Firma"
  end

  def delivery_address_1
    if company? || salutation
      result = company ? "Firma #{company}" : salutation
      xml_field('deliveryAddress1', result)
    else
      raise_error('Neither company nor salutation exists')
    end
  end

  def delivery_address_2
    fullname   = self.address.fullname if self.address
    fullname   ||= nil
    if fullname
      result = company? ? "Z.Hd. #{fullname}" : fullname
      xml_field('deliveryAddress2', result)
    else
      raise_error("No fullname exists")
    end
  end

  def delivery_address_3
    invoice_addition   = self.address.addition if self.address
    delivery_addition  = self.delivery_address.addition if self.delivery_address
    if result = delivery_addition || invoice_addition
      xml_field('deliveryAddress3', result)
    else
      ""
    end
  end

  def delivery_address_country_code
    result = self.delivery_address.country.code if self.delivery_address &&
      self.delivery_address.country &&
      self.delivery_address.country_code
    result ||= nil

    if result
      xml_field('deliveryCountryCode', result, false)
    else
      raise_error('No delivery country code exists')
    end
  end

  def delivery_place
    result = self.delivery_address.place if self.delivery_address
    if result
      xml_field('deliveryPlace', result)
    else
      ""
    end
  end

  def delivery_street
    result = self.delivery_address.street if delivery_address
    result ||= nil

    if result
      xml_field('deliveryStreet', result)
    else
      ""
    end
  end

  def delivery_zipcode
    result = self.delivery_address ? self.delivery_address.zipcode : nil
    if result
      raise_error('deliveryZipCode is too long') if result.length > 6
      xml_field('deliveryZipCode', result, true, 6)
    else
      ""
    end
  end

  def delivery_terms_code
    result = self.delivery_term
    if result
      xml_field('deliveryTermsCode',result, false)
    else
      ""
    end
  end

  def gross_price_code
    result = self.inclusive_taxes
    if result
      xml_field('grossPriceCode', result, false)
    else
      ""
    end
  end

  def invoice_address_1
    result = self.address ? self.address.salutation : nil
    if result
      xml_field('invoiceAddress1', result)
    else
      ""
    end
  end

  def invoice_address_2
    result = self.address ? self.address.fullname : nil
    if result
      xml_field('invoiceAddress2', result)
    else
      ""
    end
  end

  def invoice_address_3
    result = self.address ? self.address.addition : nil
    if result
      xml_field('invoiceAddress3', result)
    else
      ""
    end
  end

  def invoice_country_code
    result = self.address && self.address.country ? self.address.country.code : nil
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
      ""
    end
  end

  def invoice_street
    result = self.address ? self.address.street : nil
    if result
      xml_field('invoiceStreet', result)
    else
      ""
    end
  end

  def invoice_zipcode
    result = self.address ? self.address.zipcode : nil
    if result
      raise_error('invoiceZipCode is too long') if result.length > 6
      xml_field('invoiceZipCode', result, true, 6)
    else
      ""
    end
  end

  def language_id
    xml_field('languageId', 0, false)
  end

  def tax_number
    result = self.infoblock ? self.infoblock.taxno : nil
    if result
      raise_error('taxNumber is too long') if result.length > 20
      xml_field('taxNumber', result, true, 20)
    else
      ""
    end
  end

  def vat_number
    result = self.ustid || nil
    if result
      raise_error('vatNumber is too long') if result.length > 14
      xml_field('vatNumber', result, true, 14)
    else
      ""
    end
  end

  def text_1
    result = self.order_number
    if result
      xml_field('text1', result, true, 20)
    else
      ""
    end
  end

  def tax_code
    result = self.pays_taxes? ? 0 : 1
    xml_field('taxCode', result, false)
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
      return ""
    end
  end

  def raise_error(str)
    raise "#{str} for #{self.type} #{self.id}"
  end

  def to_xml
    return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Customer.xsd">
<customer>
  #{currency_code}
  #{customer_id}
  #{delivery_address_1}
  #{delivery_address_2}
  #{delivery_address_3}
  #{delivery_address_country_code}
  #{delivery_place}
  #{delivery_street}
  #{delivery_zipcode}
  #{delivery_terms_code}
  #{gross_price_code}
  #{invoice_address_1}
  #{invoice_address_2}
  #{invoice_address_3}
  #{invoice_country_code}
  #{invoice_place}
  #{invoice_street}
  #{invoice_zipcode}
  #{language_id}
  #{tax_number}
  #{tax_code}
  #{vat_number}
  #{text_1}
</customer>
</Root>
XML
  end
end
