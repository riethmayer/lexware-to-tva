# -*- coding: utf-8 -*-
require 'rubygems'
require 'hpricot'
require 'yaml'

class Converter

  attr_accessor :base, :input_dir, :output_dir, :errors
  attr_accessor :files, :directory

  BASE      = File.join(File.dirname(__FILE__), "..")

  def initialize(directory)
    self.directory  = directory || BASE
    self.input_dir  = File.join(self.directory, "input")
    self.output_dir = File.join(self.directory, "output")
    self.files = []
  end

  def convert
    collect_files
    self.files.each_with_index do |file, file_number|
      customers = get_customers_from(file)
      items = get_items_from(file)
      invoices, delivery_notes = get_orders_from(file)
      invoices.each do |invoice|
        invoice.update_fields(delivery_notes)
      end
      [ customers, items, invoices ].flatten.each_with_index do |element, element_number|
        save_as_xml(element, file_number, element_number)
      end
    end
    cleanup_files
  end

  def collect_files
    file_names = Dir.new(self.input_dir).entries - [".",".."]
    file_names.each do |file_name|
      self.files << File.join(self.input_dir,file_name)
    end
  end

  def get_customers_from(file)
    customers = []
    import_orders_from(file).each do |order|
      customers << Customer.new(order)
    end
    customers
  end

  def get_items_from(file)
    items = []
    import_orders_from(file).each do |order|
      items << Item.new(order) # may return an array
    end
    uniquify(items.flatten.compact)
  end

  def get_orders_from(file)
    invoices       = []
    delivery_notes = []
    import_orders_from(file).each do |order|
      o = Order.new(order)
      invoices << o if o.invoice?
      delivery_notes << o if o.delivery_note?
    end
    [invoices, delivery_notes]
  end

   # returns hpricot elements
  def import_orders_from(file)
    xml = File.read(file)
    doc = Hpricot::XML(xml)
    orders = []
    (doc/:Auftrag).each do |order|
      orders << order
    end
    orders
  end

  def uniquify(items)
    unique_items = { }
    items.each do |item|
      unique_items[item.id] = item
    end
    unique_items.values
  end

  def save_as_xml(element, file_number, element_number)
    File.open(create_filename_for(element, file_number, element_number), 'w') do |f|
      f.write(element.to_xml)
    end
  end

  def create_filename_for(element, file_number, element_number)
    File.join(self.output_dir, "#{element.type}_#{element.id}_#{file_number}_#{element_number}.xml")
  end

  def cleanup_files
   # Dir.new(self.directory).entries.each do |file|
   #   FileUtils.rm(File.join(self.directory, file)) if file =~ /\.xml$/
   # end
  end

  def self.xml_get(field, order)
    if order.at(field)
      order.at(field).innerHTML.strip
    else
      # puts "Field #{field} not found at << #{order.at('Betreff_NR').innerHTML.strip} >>" if order.at('Betreff_NR') && ENV['VERBOSE']
      ""
    end
  end

  def self.convert_value(str)
    str.gsub!(/,/,".")  # 23,24  => 23.24
    str.gsub!(/%/,"")   # 19.00% => 19.00
    str.strip!
    str
  end

  def self.delivery_code(str)
    delivery_code_map = {
      "01 vers. Versand"                                                  => { :shipping_code =>1,   :delivery_terms_code =>  1},
      "01 vers. Versand - versandkostenfrei"                              => { :shipping_code =>1,   :delivery_terms_code =>  1},
      "günstigster Versand - versandkostenfrei"                           => { :shipping_code =>2,   :delivery_terms_code =>  1},
      "günstigster Versand"                                               => { :shipping_code =>2,   :delivery_terms_code =>  1},
      "02 DHL National - versandkostenfrei"                               => { :shipping_code =>3,   :delivery_terms_code =>  1},
      "02 DHL National"                                                   => { :shipping_code =>3,   :delivery_terms_code =>  1},
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
    delivery_code_map[str]
  end

  def self.payment_map(str)
    payment_code_map = {
      "Zahlbar per Überweisung direkt nach Erhalt der Rechnung. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                            => { :payment_code => 1,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 7 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                => { :payment_code => 2,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 14 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => 3,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 21 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => 4,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => 5,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 50 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => 6,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 60 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                               => { :payment_code => 7,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 7 Tagen bei 2 % Skonto, innerhalb von 14 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                         => { :payment_code => 8,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 10 Tagen bei 2 % Skonto, innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => 9,  :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 30 Tagen bei 2 % Skonto, innerhalb von 60 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => 10, :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 30 Tagen bei 3 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                      => { :payment_code => 11, :payment_mode => 0 },
      "Zahlbar per Überweisung innerhalb von 10 Tagen bei 3 % Skonto, innerhalb von 30 Tagen netto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                        => { :payment_code => 12, :payment_mode => 0 },
      "Zahlbar per Vorkasse. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                               => { :payment_code => 13, :payment_mode => 4 },
      "Zahlbar per Vorkasse bei 2 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                => { :payment_code => 14, :payment_mode => 4 },
      "Zahlbar per Vorkasse bei 3 % Skonto. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                                                => { :payment_code => 15, :payment_mode => 4 },
      "Der Betrag wird per Bankeinzug 10 Tage nach Rechnungsstellung eingezogen."                                                                                                                  => { :payment_code => 16, :payment_mode => 1 },
      "Der Betrag wird per Bankeinzug 14 Tage nach Rechnungsstellung bei 3 % Skonto eingezogen."                                                                                                   => { :payment_code => 17, :payment_mode => 1 },
      "Der Betrag wird per Bankeinzug 30 Tage nach Rechnungsstellung eingezogen."                                                                                                                  => { :payment_code => 18, :payment_mode => 1 },
      "Der Betrag wird per Bankeinzug 30 Tage nach Rechnungsstellung bei 3 % Skonto eingezogen."                                                                                                   => { :payment_code => 19, :payment_mode => 1 },
      "Bereitstellung der Ware für einen Testzeitraum von 30 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => 20, :payment_mode => 0 },
      "Bereitstellung der Ware für einen Testzeitraum von 50 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => 21, :payment_mode => 0 },
      "Bereitstellung der Ware für einen Testzeitraum von 60 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => 22, :payment_mode => 0 },
      "Bereitstellung der Ware für einen Testzeitraum von 90 Tagen. Für innerhalb des Testzeitraums zurückgesendete Ware gilt volles Remissionsrecht."                                             => { :payment_code => 23, :payment_mode => 0 },
      "Bezahlung per Nachnahme bei Erhalt der Lieferung."                                                                                                                                          => { :payment_code => 24, :payment_mode => 3 },
      "50% zahlbar per Vorkasse. 50% direkt nach Erhalt der Rechnung. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                      => { :payment_code => 25, :payment_mode => 4 },
      "50% zahlbar per Vorkasse. 50% per Überweisung innerhalb 14 Tagen. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                   => { :payment_code => 26, :payment_mode => 4 },
      "50% zahlbar per Vorkasse. 50% per Überweisung innerhalb 30 Tagen. Bei Überweisungen bitte immer die Kunden- und Rechnungsnummer angeben."                                                   => { :payment_code => 27, :payment_mode => 4 },
      "The amount must be paid by remittance to our bank account directly after receiving the invoice. When transferring the amount please advice invoice number and customer number."             => { :payment_code => 28, :payment_mode => 0 },
      "The amount must be paid by remittance to our bank account within 7 days after date of the invoice. When transferring the amount please advice invoice number and customer number."          => { :payment_code => 29, :payment_mode => 0 },
      "The amount must be paid by remittance to our bank account within 14 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => 30, :payment_mode => 0 },
      "The amount must be paid by remittance to our bank account within 30 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => 31, :payment_mode => 0 },
      "The amount must be paid by remittance to our bank account within 60 days after date of the invoice. When transferring the amount please advice invoice number and customer number."         => { :payment_code => 32, :payment_mode => 0 },
      "Advance payment by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                                          => { :payment_code => 33, :payment_mode => 4 },
      "Advance payment with 2 % cash discount by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                   => { :payment_code => 34, :payment_mode => 4 },
      "Advance payment with 3 % cash discount by remittance to our bank account. When transferring the amount please advice invoice number and customer number."                                   => { :payment_code => 35, :payment_mode => 4 },
      "bank collection after 14 days with 3 % cash discount."                                                                                                                                      => { :payment_code => 36, :payment_mode => 1 },
      "Advance payment of 50 % by remittance to our bank account. 50 % directly after receiving the invoice. When transferring the amount please advice invoice number and customer number."       => { :payment_code => 37, :payment_mode => 4 },
      "Advance payment of 50 % by remittance to our bank account. 50 % within 14 days after date of the invoice. When transferring the amount please advice invoice number and customer number."   => { :payment_code => 38, :payment_mode => 4 },
      "Advance payment of 50 % by remittance to our bank account. 50 % within 30 days after date of the invoice. When transferring the amount please advice invoice number and customer number."   => { :payment_code => 39, :payment_mode => 4 }
    }
    payment_code_map[str]
  end

  def self.representative_map(str)
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
    representatives[str]
  end
end
