# -*- coding: utf-8 -*-
require 'rubygems'
require 'hpricot'

class Converter

  attr_accessor :file, :filename, :raw_orders, :tmp_directory, :tmp_filename
  attr_accessor :customers, :items, :invoices, :delivery_notes
  attr_accessor :customer_count, :item_count, :order_count
  attr_accessor :errors, :warnings

  BASE   = File.join(FileUtils.pwd,"tmp", "conversions")
  ## BASE   = File.join(FileUtils.pwd,"..","test", "data", "output")

  def initialize(default = nil)
    self.import(default) if default
  end

  def import(filename)
    self.errors = []
    self.warnings = []
    self.filename            = filename
    self.file                = File.open(filename, 'r:windows-1252:utf-8')
    self.raw_orders          = import_raw_orders
    self.customers           = get_customers
    self.customer_count      = self.customers.length
    self.items               = get_items
    self.item_count          = self.items.length
    # split orders into invoices and delivery notes
    invoices, delivery_notes = get_orders
    self.invoices            = invoices
    self.order_count         = self.invoices.length
    self.delivery_notes      = delivery_notes
    self.tmp_filename        = Time.now.strftime("%Y%m%d%H%M%S")
    self.tmp_directory       = create_tmp_directory
  end

  def convert
    self.invoices.each do |invoice|
      invoice.update_fields(self.delivery_notes)
    end
    [ self.customers,
      self.items,
      self.invoices
    ].flatten.each_with_index do |element, element_number|
      save_as_xml(element, element_number)
      save_as_error_log(element, element_number)
      save_as_warn_log(element,element_number)
    end
    return compressed_files
  end

  # returns hpricot elements
  def import_raw_orders
    xml = self.file.read
    doc = Hpricot::XML(xml)
    orders = []
    (doc/:Auftrag).each do |order|
      orders << order
    end
    orders
  end

  def get_customers
    customers = []
    self.raw_orders.each do |order|
      customer = Customer.new(order)
      customers << customer if customer.valid?
      self.errors << customer.to_error_log unless customer.valid?
      self.warnings << customer.to_warning_log unless customer.clean?
    end
    uniquify(customers)
  end

  def get_items
    all_items = []
    self.raw_orders.each do |order|
      order = Order.new(order)
      all_items << order.positions
    end
    items = []
    all_items.each do |positions|
      positions.each do |item|
        items << item if item.valid?
        self.errors << item.to_error_log   unless item.valid?
        self.errors << item.to_warning_log unless item.clean?
      end
    end
    # 20 different orders each with 1 same item
    # each item has different price
    # then only save 1 file right?
    # TODO check!
    uniquify(items.flatten.compact)
  end

  def get_orders
    invoices       = []
    delivery_notes = []
    self.raw_orders.each do |order|
      o = Order.new(order)
      invoices << o if o.invoice?
      delivery_notes << o if o.delivery_note?
    end
    [invoices, delivery_notes]
  end

  def uniquify(items)
    unique_items = { }
    items.each do |item|
      unique_items[item.id] = item unless unique_items[item.id] # first item
      unique_items[item.id] = item if item.valid? # valid items take precedence
    end
    unique_items.values
  end

  def save_as_xml(element, element_number)
    File.open(create_filename_for(element, element_number), 'w') do |f|
      res = element.to_xml
      f.write(res)
    end
  end

  def save_as_error_log(element, element_number)
    error = element.to_error_log
    self.errors << error
    File.open(create_filename_for(element, element_number,'error.log'), 'w') do |f|
      f.write(error)
    end
  end

  def save_as_warn_log(element, element_number)
    warning = element.to_warning_log
    self.warnings << warning
    File.open(create_filename_for(element, element_number,'warning.log'), 'w') do |f|
      f.write(element.to_warning_log)
    end
  end

  def create_filename_for(element, element_number, extension = 'xml')
    File.join(self.tmp_directory, "#{element.type}_#{element.id}_#{element_number}.#{extension}")
  end

  # in case a file is already present in this directory, it will survive
  def create_tmp_directory
    self.tmp_directory = File.join(BASE,self.tmp_filename,"")
    FileUtils.mkdir_p(self.tmp_directory)[0]
  end

  def compressed_files
    FileUtils.cd(self.tmp_directory)
    `zip #{self.tmp_filename}.zip *.*`
    xml_file = File.new("#{self.tmp_filename}.zip")
    return xml_file
  end

  def cleanup_temporary_files
    FileUtils.rm_rf(self.tmp_directory)
  end

  def error_report
    self.errors.flatten.uniq.join("\n")
  end

  def warn_report
    self.warnings.flatten.uniq.join("\n")
  end

  def self.xml_get(field, order)
    if order.at(field)
      order.at(field).innerHTML.gsub(/\s/," ").gsub(/( )+/," ").strip
    else
      unless is_optional?(field)
        raise "Field #{field} not found at << #{order.at('Betreff_NR').innerHTML.strip} >>" if order.at('Betreff_NR')
      end
    end
  end

  def self.convert_value(str)
    str.gsub!(/,/,".")  # 23,24  => 23.24
    str.gsub!(/%/,"")   # 19.00% => 19.00
    str.strip!
    str
  end

  def self.delivery_code(str)
    str = str.force_encoding('UTF-8')
    delivery_code_map = {
      "01 vers. Versand"                                                  => { :shipping_code =>1,   :delivery_terms_code =>  1},
      "01 vers. Versand - versandkostenfrei"                              => { :shipping_code =>1,   :delivery_terms_code =>  1},
      "günstigster Versand - versandkostenfrei"                           => { :shipping_code =>2,   :delivery_terms_code =>  1},
      "günstigster Versand"                                               => { :shipping_code =>2,   :delivery_terms_code =>  1},
      "02 DHL National - versandkostenfrei"                               => { :shipping_code =>3,   :delivery_terms_code =>  1},
      "02 DHL National"                                                   => { :shipping_code =>3,   :delivery_terms_code =>  1},
      "03 Express"                                                        => { :shipping_code =>26,  :delivery_terms_code =>  1},
      "DPD Paket - versandkostenfrei"                                     => { :shipping_code =>4,   :delivery_terms_code =>  1},
      "DPD Paket"                                                         => { :shipping_code =>4,   :delivery_terms_code =>  1},
      "DPD Int - versandkostenfrei"                                       => { :shipping_code =>4,   :delivery_terms_code =>  1},
      "DPD Int"                                                           => { :shipping_code =>4,   :delivery_terms_code =>  1},
      "DHL Int Economy - free delivery"                                   => { :shipping_code =>5,   :delivery_terms_code =>  1},
      "DHL Int Economy"                                                   => { :shipping_code =>5,   :delivery_terms_code =>  1},
      "DHL Int Premium - free delivery"                                   => { :shipping_code =>6,   :delivery_terms_code =>  1},
      "DHL Int Premium"                                                   => { :shipping_code =>6,   :delivery_terms_code =>  1},
      "EXW (Abholort)"                                                    => { :shipping_code =>7,   :delivery_terms_code =>  2},
      "EXW Leinatal"                                                      => { :shipping_code =>7,   :delivery_terms_code =>  3},
      "FOB Hamburg - bis Abfahrtshafen von Spediteur des Versenders"      => { :shipping_code =>8,   :delivery_terms_code =>  4},
      "FOB Hamburg - ab Lager durch Seefrachtführer"                      => { :shipping_code =>7,   :delivery_terms_code =>  4},
      "FOB Bremerhaven - bis Abfahrtshafen von Spediteur des Versenders"  => { :shipping_code =>8,   :delivery_terms_code =>  5},
      "FOB Bremerhaven - ab Lager durch Seefrachtführer"                  => { :shipping_code =>7,   :delivery_terms_code =>  5},
      "FCA (Abflughafen) - bis Abflughafen von Spediteur des Versenders"  => { :shipping_code =>8,   :delivery_terms_code =>  6},
      "FCA (Abflughafen) - ab Lager durch Luftfrachtführer"               => { :shipping_code =>7,   :delivery_terms_code =>  6},
      "CIF (Zielhafen) - bis Abfahrtshafen von Spediteur des Versenders"  => { :shipping_code =>8,   :delivery_terms_code =>  7},
      "CIF (Zielhafen) - bis Zielhafen von Spediteur des Versenders"      => { :shipping_code =>8,   :delivery_terms_code =>  7},
      "CIF (Zielhafen) - ab Lager durch Seefrachtführer"                  => { :shipping_code =>7,   :delivery_terms_code =>  7},
      "CFR (Zielhafen) - bis Abfahrtshafen von Spediteur des Versenders"  => { :shipping_code =>8,   :delivery_terms_code =>  8},
      "CFR (Zielhafen) - bis Zielhafen von Spediteur des Versenders"      => { :shipping_code =>8,   :delivery_terms_code =>  8},
      "CFR (Zielhafen) - ab Lager durch Seefrachtführer"                  => { :shipping_code =>7,   :delivery_terms_code =>  8},
      "Spedition AZ - versandkostenfrei"                                  => { :shipping_code =>9,   :delivery_terms_code =>  1},
      "Spedition AZ"                                                      => { :shipping_code =>9,   :delivery_terms_code =>  1},
      "TNT overnight"                                                     => { :shipping_code =>10,  :delivery_terms_code =>  1},
      "TNT bis 08:00"                                                     => { :shipping_code =>11,  :delivery_terms_code =>  1},
      "TNT bis 09:00"                                                     => { :shipping_code =>12,  :delivery_terms_code =>  1},
      "TNT bis 10:00"                                                     => { :shipping_code =>13,  :delivery_terms_code =>  1},
      "TNT bis 12:00"                                                     => { :shipping_code =>14,  :delivery_terms_code =>  1},
      "TNT Samstag"                                                       => { :shipping_code =>15,  :delivery_terms_code =>  1},
      "TNT overnight versichert"                                          => { :shipping_code =>16,  :delivery_terms_code =>  1},
      "00 versandkostenfrei"                                              => { :shipping_code =>1,   :delivery_terms_code =>  1},
      "Post und DHL günstigster Versand"                                  => { :shipping_code =>17,  :delivery_terms_code =>  1},
      "UPS Standard"                                                      => { :shipping_code =>18,  :delivery_terms_code =>  1},
      "UPS Express 10:30"                                                 => { :shipping_code =>19,  :delivery_terms_code =>  1},
      "UPS Express Plus 8:30"                                             => { :shipping_code =>20,  :delivery_terms_code =>  1},
      "UPS Standard Samstag"                                              => { :shipping_code =>21,  :delivery_terms_code =>  1},
      "Warensendung Standard"                                             => { :shipping_code =>22,  :delivery_terms_code =>  1},
      "Warensendung Kompakt"                                              => { :shipping_code =>23,  :delivery_terms_code =>  1},
      "Warensendung Maxi"                                                 => { :shipping_code =>24,  :delivery_terms_code =>  1},
      "Fedex"                                                             => { :shipping_code =>25,  :delivery_terms_code =>  1}
    }
    result = delivery_code_map[str]
    raise "Undefined delivery '#{str}'" unless result
    result
  end

  def self.payment_code(str)
    str = str.force_encoding('UTF-8')
    payment_code_map = {
      "Zahlbar per Überweisung direkt nach Erhalt der Rechnung. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                            => { :payment_code => "1",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 7 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                => { :payment_code => "2",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 10 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "40", :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 14 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "3",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 21 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "4",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "5",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 50 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "6",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 60 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => "7",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 7 Tagen bei 2 % Skonto, innerhalb von 14 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                         => { :payment_code => "8",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 10 Tagen bei 2 % Skonto, innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => "9",  :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 30 Tagen bei 2 % Skonto, innerhalb von 60 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => "10", :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 30 Tagen bei 3 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                      => { :payment_code => "11", :payment_mode => "0" },
      "Zahlbar per Überweisung innerhalb von 10 Tagen bei 3 % Skonto, innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => "12", :payment_mode => "0" },
      "Zahlbar per Vorkasse. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                               => { :payment_code => "13", :payment_mode => "4" },
      "Zahlbar per Vorkasse bei 2 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                => { :payment_code => "14", :payment_mode => "4" },
      "Zahlbar per Vorkasse bei 3 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                => { :payment_code => "15", :payment_mode => "4" },
      "Der Betrag wird per Bankeinzug 10 Tage nach Rechnungsstellung eingezogen."                                                                                                                  => { :payment_code => "16", :payment_mode => "1" },
      "Der Betrag wird per Bankeinzug 14 Tage nach Rechnungsstellung bei 3 % Skonto eingezogen."                                                                                                   => { :payment_code => "17", :payment_mode => "1" },
      "Der Betrag wird per Bankeinzug 30 Tage nach Rechnungsstellung eingezogen."                                                                                                                  => { :payment_code => "18", :payment_mode => "1" },
      "Der Betrag wird per Bankeinzug 30 Tage nach Rechnungsstellung bei 3 % Skonto eingezogen."                                                                                                   => { :payment_code => "19", :payment_mode => "1" },
      "Bereitstellung der Ware für einen Testzeitraum von 30 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => "20", :payment_mode => "0" },
      "Bereitstellung der Ware für einen Testzeitraum von 50 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => "21", :payment_mode => "0" },
      "Bereitstellung der Ware für einen Testzeitraum von 60 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => "22", :payment_mode => "0" },
      "Bereitstellung der Ware für einen Testzeitraum von 90 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => "23", :payment_mode => "0" },
      "Bezahlung per Nachnahme bei Erhalt der Lieferung."                                                                                                                                          => { :payment_code => "24", :payment_mode => "3" },
      "50% zahlbar per Vorkasse. 50% direkt nach Erhalt der Rechnung. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                      => { :payment_code => "25", :payment_mode => "4" },
      "50% zahlbar per Vorkasse. 50% per Überweisung innerhalb 14 Tagen. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                   => { :payment_code => "26", :payment_mode => "4" },
      "50% zahlbar per Vorkasse. 50% per Überweisung innerhalb 30 Tagen. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                   => { :payment_code => "27", :payment_mode => "4" },
      "The amount must be paid by remittance to our bank account directly after receiving the invoice. When transferring the amount please advice invoice number and customer number."             => { :payment_code => "28", :payment_mode => "0" },
      "The amount must be paid by remittance to our bank account within 7 days after date of the invoice. When transferring the amount please advice invoice number and customer number."          => { :payment_code => "29", :payment_mode => "0" },
      "The amount must be paid by remittance to our bank account within 10 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => "41", :payment_mode => "0" },
      "The amount must be paid by remittance to our bank account within 14 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => "30", :payment_mode => "0" },
      "The amount must be paid by remittance to our bank account within 30 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => "31", :payment_mode => "0" },
      "The amount must be paid by remittance to our bank account within 60 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => "32", :payment_mode => "0" },
      "Advance payment by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                                          => { :payment_code => "33", :payment_mode => "4" },
      "Advance payment with 2 % cash discount by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                   => { :payment_code => "34", :payment_mode => "4" },
      "Advance payment with 3 % cash discount by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                   => { :payment_code => "35", :payment_mode => "4" },
      "bank collection after 14 days with 3 % cash discount."                                                                                                                                      => { :payment_code => "36", :payment_mode => "1" },
      "Advance payment of 50 % by remittance to our bank account. 50 % directly after receiving the invoice. When transferring the amount please advice invoice number and customer number."       => { :payment_code => "37", :payment_mode => "4" },
      "Advance payment of 50 % by remittance to our bank account. 50 % within 14 days after date of the invoice. When transferring the amount please advice invoice number and customer number."   => { :payment_code => "38", :payment_mode => "4" },
      "Advance payment of 50 % by remittance to our bank account. 50 % within 30 days after date of the invoice. When transferring the amount please advice invoice number and customer number."   => { :payment_code => "39", :payment_mode => "4" }
    }

    result = payment_code_map[str]
    raise "Undefined payment '#{str}'" unless result
    result
  end

  def self.representatives(str)
    representatives = {
      "1 SON"     => 1,
      "15_VAN"    => 2,
      "2 FIN"     => 3,
      "3 OKI"     => 4,
      "4 BRU"     => 5,
      "5.1 VER1"  => 6,
      "5.2 VER2"  => 7,
      "5.3 VER3"  => 8,
      "6 TIL"     => 9,
      "7 JOK"     => 10 }
    result = representatives[str]
    raise "Undefined representative '#{str}'" unless result
    result
  end

  def self.is_optional?(field)
    %w(Nachbem KdNrbeimLief Nebenleistungen Bestellnr AUFTR_IST_GES_RAB_BETRAG_Text Bezugsnummer).include?(field)
  end

  def self.convert_date(date)
    date_match = date.match /(\d\d|\d)\.(\d\d)\.(\d\d\d\d)/
    if date_match && date_match.length == 4
      "#{date_match[3]}-#{date_match[2]}-#{date_match[1]}"
    else
      date
    end
  end

  def save!
  end
end
