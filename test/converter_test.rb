# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class ConverterTest < Test::Unit::TestCase

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def test_import_orders_from_file
    # orders = @converter.import_orders_from(TESTFILE)
    # assert_equal 73, orders.length
  end

  def test_convert_sends_and_moves_files_from_input_dir
    # @converter.convert
  end

  def test_delivery_codes
    assert_equal 15, Converter.delivery_code('TNT Samstag')[:shipping_code]
  end

  def test_complete_items_count_is_111
    @converter = Converter.new(make_file("111_items"))
    assert_equal 111, @converter.item_count
    assert_equal 1, @converter.order_count
    assert @converter.customer_count == 1, "Expected one customer. #{@converter.error_report}"
    assert_match @converter.tmp_filename, @converter.tmp_directory
    assert_equal @converter.invoices.size, @converter.delivery_notes.size
  end

  def test_invoice_address
    @converter = Converter.new(make_file("111_items"))
    invoice = @converter.invoices[0]
    adr = invoice.address.street
    name= invoice.address.fullname
    comp= invoice.address.company
    add = invoice.address.addition
    assert adr =~ /Reichenbergerstr/, "#{adr} was expected to be Reichenberger first."
    assert name=~ /Ali/, "#{name} was expected to be Ali abi."
    assert comp=~ /TESTKUNDE GmbH/, "#{comp} was expected to be TESTKUNDE GmbH."
    assert add =~ /Testspezialist/, "#{add} was expected to be Testspezialist"
    assert_equal 49, invoice.address.country.code
  end

  def test_delivery_address
    @converter = Converter.new(make_file("111_items"))
    delivery_note = @converter.delivery_notes[0]
    adr = delivery_note.address.street
    name= delivery_note.address.fullname
    comp= delivery_note.address.company
    add = delivery_note.address.addition
    assert adr =~ /Kreuzbergstra/, "#{adr} was expected to be Kreuzbergstrasse."
    assert name=~ /Peter Hoffmann/, "#{name} was expected to be Peter."
    assert comp=~ /Versandfirma/, "#{comp} was expected to be Versandfirma."
    assert add =~ /Versandspezialist/, "#{add} was expected to be Versandspezialist"
    assert_equal 49, delivery_note.address.country.code
  end

  def test_invoice_address_remains_the_same_after_conversion
    @converter = Converter.new(make_file("111_items"))
    @converter.convert
    invoice = @converter.invoices[0]
    adr = invoice.address.street
    name= invoice.address.fullname
    comp= invoice.address.company
    add = invoice.address.addition
    assert adr =~ /Reichenbergerstr/, "#{adr} was expected to be Reichenberger first."
    assert name=~ /Ali/, "#{name} was expected to be Ali abi."
    assert comp=~ /TESTKUNDE GmbH/, "#{comp} was expected to be TESTKUNDE GmbH."
    assert add =~ /Testspezialist/, "#{add} was expected to be Testspezialist"
    assert_equal 49, invoice.address.country.code
  end

  def test_invoice_address_in_xml_document
    @converter = Converter.new(make_file("111_items"))
    @converter.convert
    invoice = @converter.invoices[0]
    xml = invoice.to_xml
    assert /<invoiceCountryCode>49<\/invoiceCountryCode>/                    =~ xml
    assert /<invoiceName1><!\[CDATA\[Frau\/Herr\/Firma\]\]><\/invoiceName1>/ =~ xml, "Salutation missing in invoiceName1"
    assert /<invoiceName2><!\[CDATA\[Ali .+?\]\]><\/invoiceName2>/        =~ xml, "Expected Ali in invoiceName2"
    assert /<invoiceName3><!\[CDATA\[Testspezialist\]\]><\/invoiceName3>/    =~ xml, "Expected Testspezialist in invoiceName3"
    assert /<invoicePlace><!\[CDATA\[Berlin\]\]><\/invoicePlace>/            =~ xml, "Expected Berlin in invoicePlace"
    assert /<invoiceZipCode><!\[CDATA\[10999\]\]><\/invoiceZipCode>/         =~ xml, "Expected 10999 in invoiceZipCode"
    assert /<invoiceStreet><!\[CDATA\[Reichenbergerstra.+?e 123\]\]><\/invoiceStreet>/ =~ xml, "Expected Reichenberger as invoiceStreet"
  end

  def test_delivery_address_in_xml_document
    @converter = Converter.new(make_file("111_items"))
    @converter.convert
    invoice = @converter.invoices[0]
    xml = invoice.to_xml
    assert /<deliveryCountryCode>49<\/deliveryCountryCode>/                          =~ xml
    assert /<deliveryName1><!\[CDATA\[Firma Versandfirma\]\]><\/deliveryName1>/      =~ xml
    assert /<deliveryName2><!\[CDATA\[Z\.Hd\. Peter Hoffmann\]\]><\/deliveryName2>/    =~ xml
    assert /<deliveryName3><!\[CDATA\[Versandspezialist\]\]><\/deliveryName3>/       =~ xml
    assert /<deliveryPlace><!\[CDATA\[Berlin\]\]><\/deliveryPlace>/                  =~ xml
    assert /<deliveryStreet><!\[CDATA\[Kreuzbergstra.+?e 61\]\]><\/deliveryStreet>/  =~ xml
    assert /<deliveryZipCode><!\[CDATA\[10961\]\]><\/deliveryZipCode>/               =~ xml
  end

  def test_delivery_note_address_exists_after_conversion
    @converter = Converter.new(make_file("111_items"))
    @converter.convert
    address = @converter.invoices[0].delivery_address
    assert address.street =~ /Kreuzbergstra/, "#{address.street} is not Kreuzbergstr."
    assert address.company =~ /Versandfirma/, "#{address.company} is not Versandfirma."
    assert address.fullname =~ /Peter Hoffmann/, "#{address.fullname} is not Peter."
  end

  def test_convert_generates_zip_file
    @converter = Converter.new(make_file("111_items"))
    assert @converter.tmp_filename
    file = @converter.convert
  end

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end
end
