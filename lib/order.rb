# -*- encoding: utf-8 -*-
class Order
  attr_accessor :positions, :customer, :order, :address, :delivery_address
  attr_accessor :shipping, :discount
  attr_accessor :invoice_print_code
  attr_accessor :additional_text, :is_delivery_note, :delivery_note, :is_invoice
  attr_accessor :order_number, :description, :order_type
  attr_accessor :order_confirmation_id, :delivery_note_id, :id, :deliverer_id
  attr_accessor :errors, :warnings

  def initialize(default = nil)
    self.import(default) if default
  end

  def import(order)
    self.errors = []
    self.warnings = []
    self.order                      = order
    ## Finde erst mal heraus was ich bin
    # Lieferschein oder Rechnung?
    invoice_or_delivery_note
    self.customer                   = Customer.new(order)
    self.address                    = self.customer.address
    self.additional_text            = Converter.xml_get('Nachbem',order)
    self.order_number               = Converter.xml_get('Bestellnr', order)
    self.description                = Converter.xml_get('Auftragsbeschreibung', order)
    discount_wrapper                = order.at('AUFTR_IST_GES_RAB_BETRAG_Text')
    self.discount                   = discount_wrapper ? Converter.xml_get('AUFTR_IST_GES_RAB_BETRAG_Text', discount_wrapper) : nil
    extract_deliverer_id
    get_positions
    update_invoice_print_code
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

  def valid?
    self.errors << "customer_id is missing" unless self.customer && self.customer.id
    self.errors << "deliveryCountryCode is missing" unless self.delivery_address && self.delivery_address.has_country_code?
    self.errors << "deliveryTermsCode is missing"   unless self.customer.delivery_terms_code
    self.errors << "invoiceCountryCode is missing" unless self.address && self.address.has_country_code?
    self.errors << "orderType is missing" unless self.order_type
    self.errors << "paymentCode is missing" unless self.customer.payment_code
    self.errors << "paymentMode is missing" if self.customer.payment_mode.nil?
    self.errors << "shippingCode is missing" unless self.customer.shipping_code
    self.errors.empty?
  end

  def clean?
    self.warnings.empty?
  end

  def to_error_log
    return nil if self.errors.empty?
    self.errors.flatten.join("\n")
  end

  def to_warning_log
    return nil if self.warnings.empty?
    self.warnings.flatten.join("\n")
  end

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
      self.invoice_print_code = "0"
    else
      self.invoice_print_code = "1"
    end
  end
  # conversion from comma to point values
  def extract_discount
    m = self.discount.match(/abzgl. (\d\d|\d),(\d\d)/)
    m ? "#{m[1]}.#{m[2]}" : nil
  end

  # extrem wichtig, dass die einzelnen Positionen samt Preis gespeichert werden
  def get_positions
    self.positions = []
    (self.order/:PosNr).each do |position|
      item = Item.new(position)
      self.positions << item if !item.placeholder? && item.valid?
      self.errors << item.to_error_log unless item.placeholder? || item.valid?
      self.warnings << item.to_warning_log unless item.clean?
    end
  end
      # Lieferkosten, Versicherung
  def set_additional_costs
    if Converter.xml_get('Nebenleistungen', self.order)
      self.shipping = {
        :text => Converter.xml_get('Nebenleistungen_Text', self.order),
        :value => Converter.convert_value(Converter.xml_get('Nebenleistungen_Betrag', self.order))
      }
      self.shipping = nil if self.shipping[:text].length == 0 && self.shipping[:value].length == 0
    else
      self.shipping = nil
    end
  end

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
        self.order_confirmation_id = d.order_confirmation_id
      end
    end
    update_invoice_print_code
  end

  def type
    invoice? ? "Invoice" : "DeliveryNote"
  end

  def error_id
    self.id || self.delivery_note_id || self.order_confirmation_id
  end

  def urgent?
    self.description && self.description.downcase.match(%r{(eilt|eilig|urgent|schnell|asap|immed)})
  end

  def add_costs?
    !!self.shipping
  end

  ## XML OUTPUT ##

  def add_costs_xml
    if self.add_costs?
      txt = self.shipping[:text]
      val = self.shipping[:value]
      if txt && val
        return [xml_field('addCosts1', txt), xml_field('addCostsValue1', val, false)].join("\n")
      else
        raise_error("Shipping costs invalid: text => '#{txt}', value => '#{val}'")
      end
    else
      nil
    end
  end

  def additional_text_xml
    result = self.additional_text.to_s.length > 0 ? self.additional_text : nil
    if result
      xml_field('addText', result, true, 250)
    else
      nil
    end
  end

  def customer_id
    result = self.customer ? self.customer.id : nil
    if result
      xml_field('customerId', result, false)
    else
      raise_error('CustomerId missing')
    end
  end

  def delivery_country_code
    if  self.delivery_address &&
        self.delivery_address.country &&
        self.delivery_address.country.code
      result = self.delivery_address.country.code
      xml_field('deliveryCountryCode', result, false)
    elsif !self.delivery_address
      if self.address && self.address.country && self.address.country.code
        self.delivery_address = self.address
        xml_field('deliveryCountryCode', self.address.country.code, false)
      else
        raise_error("Has neither valid invoice- nor delivery-address")
      end
    elsif !self.delivery_address.country
      raise_error("delivery_address.country missing")
    else
      raise_error("delivery_address.country.code missing")
    end
  end

  def delivery_date_xml
    result = self.customer.infoblock.delivered_at
    if result
      xml_field('deliveryDate', result, false)
    else
      nil
    end
  end

  def delivery_company
    self.delivery_address ? self.delivery_address.company : nil
  end

  def delivery_salutation
    result = self.delivery_address ? self.delivery_address.salutation : nil
  end

  def delivery_fullname
    self.delivery_address ? self.delivery_address.fullname : nil
  end

  def delivery_name_1
    result = delivery_company ? delivery_company : (delivery_salutation || nil )
    if result
      xml_field('deliveryName1', result)
    else
      nil
    end
  end

  def delivery_name_2
    result = delivery_company && delivery_fullname ? delivery_fullname : nil
    if result
      xml_field('deliveryName2', result)
    else
      nil
    end
  end

  def delivery_name_3
    result = self.delivery_address ? self.delivery_address.addition : nil
    if result
      xml_field('deliveryName3', result)
    else
      nil
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

  # is always 1
  def delivery_print_code
    "1"
  end

  def delivery_print_code_xml
    xml_field('deliveryPrintCode', delivery_print_code, false)
  end

  def delivery_street
    result = self.delivery_address ? self.delivery_address.street : nil
    if result
      xml_field('deliveryStreet', result)
    else
      nil
    end
  end

  def delivery_codes
    fst = self.customer.shipping_code
    snd = self.customer.delivery_terms_code
    if fst && snd
      [
       xml_field('shippingCode', fst, false),
       xml_field('deliveryTermsCode', snd, false)
      ].join("\n")
    else
      raise_error("deliveryTermsCode (#{fst}) or shippingCode (#{snd}) missing")
    end
  end

  def delivery_zipcode
    result = self.delivery_address ? self.delivery_address.zipcode : nil
    if result
      raise_error("deliveryZipCode is longer than 6 chars") if result.length > 6
      xml_field('deliveryZipCode', result, true, 6)
    else
      nil
    end
  end

  def discount_xml
    result = self.discount ? extract_discount : nil
    if result
      xml_field('discount1', result, false)
    else
      nil
    end
  end

  def gross_price_code
    #result = self.customer && self.customer.pays_taxes? ? 1 : 0
    xml_field('grossPriceCode', 0, false)
  end

  def tax_code
    result = self.customer && self.customer.pays_taxes? ? 1 : 0
    [
      xml_field('taxCode', result, false),
      xml_field('netInvoicingCode', result, false)
    ].join("\n")
  end

  def invoice_country_code
    result = self.address && self.address.country ? self.address.country.code : nil
    if result
      xml_field('invoiceCountryCode', result, false)
    else
      raise_error('invoiceCountryCode missing')
    end
  end

  def invoice_name_1
    result = self.address ? self.address.company : (self.address.salutation || nil)
    xml_field('invoiceName1', result)
  end

  def invoice_name_2
    result = self.address ? self.address.fullname : nil
    if result
      xml_field('invoiceName2', result)
    else
      nil
    end
  end

  def invoice_name_3
    result = self.address ? self.address.addition : nil
    if result
      xml_field('invoiceName3', result)
    else
      nil
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

  def invoice_print_code_xml
    xml_field('invoicePrintCode', self.invoice_print_code, false)
  end

  def invoice_street
    result = self.address ? self.address.street : nil
    if result
      xml_field('invoiceStreet', result)
    end
  end

  def invoice_zipcode
    result = self.address ? self.address.zipcode : nil
    if result
      raise_error("invoiceZipCode ist too long") if result.length > 6
      xml_field('invoiceZipCode', result, true, 6)
    else
      nil
    end
  end

  # ist standardmaessig 1 bei uns
  def order_type
    xml_field('orderType', 1, false)
  end

  def payment_codes
    if self.customer.payment_code && %w(0 1 2 3 4).include?(self.customer.payment_mode.to_s)
      [
       xml_field('paymentCode', self.customer.payment_code, false),
       xml_field('paymentMode', self.customer.payment_mode, false)
      ].join("\n")
    else
      raise_error("Payment invalid")
    end
  end

  def reference_1
    result = self.order_confirmation_id || nil
    if result
      xml_field('reference1', result.to_s)
    else
      nil
    end
  end

  def reference_2
    fst = self.order_number
    snd = self.deliverer_id
    if fst && snd
      xml_field('reference2', "#{fst} ; #{snd}")
    elsif fst
      xml_field('reference2', fst)
    elsif snd
      xml_field('reference2', snd)
    else
      nil
    end
  end

  def representative_1
    result = Converter.representatives(self.customer.infoblock.editor) || nil
    if result
      xml_field('representative1', result, false)
    end
  end

  def short_name
    result = self.customer ? self.customer.short_name : nil
    if result
      xml_field('shortName', result, true, 10)
    else
      nil
    end
  end

  def urgent_code
    urgency = self.urgent? ? 1 : 0
    xml_field('urgentCode', urgency, false )
  end

  def order_release_code
    result = self.customer.payment_mode && self.customer.payment_mode == "4"
    if result
      xml_field('orderReleaseCode', "1", false)
    end
  end

  def raise_error(str)
    raise "#{str} for #{self.type} #{self.error_id}"
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

  def xml_for(items)
    xmls = []
    items.each do |item|
      xmls << item.xml_partial
    end
    xmls.join("\n")
  end

  # ATT: delivery_country_code must have precedence before all other address related
  #      methods, as this is a mandatory field and delivery_address will be
  #      invoice address if no invoice address is specified
  #      The order is important, as delivery notes update invoices, so this info
  #      is the most recent
  def to_xml

    prelude = "<?xml version='1.0'?>\n<Root xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:noNamespaceSchemaLocation='file:///order.xsd'>\n<order>"
    str= [ add_costs_xml,
           additional_text_xml,
           customer_id,
           delivery_country_code,
           delivery_date_xml,
           delivery_name_1,
           delivery_name_2,
           delivery_name_3,
           delivery_place,
           delivery_print_code_xml,
           delivery_street,
           delivery_codes,
           delivery_zipcode,
           discount_xml,
           gross_price_code,
           invoice_country_code,
           invoice_name_1,
           invoice_name_2,
           invoice_name_3,
           invoice_place,
           invoice_print_code_xml,
           invoice_street,
           invoice_zipcode,
           order_type,
           payment_codes,
           reference_1,
           reference_2,
           representative_1,
           short_name,
           urgent_code,
           tax_code,
           order_release_code
         ].compact
    str.each do |s|
      s = s.force_encoding('UTF-8')
    end
    all = str.join("\n")
    ending = "<positionen AnzPos='#{positions.length}'>#{xml_for(positions)}</positionen>\n</order>\n</Root>"
    prelude + all + ending
  end

  def save!
  end
end
