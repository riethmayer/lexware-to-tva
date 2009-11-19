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
    assert_equal 1, @converter.customer_count
    assert_match @converter.tmp_filename, @converter.tmp_directory
    assert_equal @converter.invoices.size, @converter.delivery_notes.size
  end


  def test_delivery_note_address_overwrites_invoice_address
    @converter = Converter.new(make_file("111_items"))
    tmp = @converter.invoices[0]
    adr = tmp.address.street
    name= tmp.address.fullname
    comp= tmp.address.company
    assert adr =~ /Reichenbergerstr/, "#{adr} was expected to be Reichenberger first."
    assert name=~ /Ali/, "#{name} was expected to be Ali abi."
    assert comp=~ /TESTKUNDE GmbH/, "#{comp} was expected to be TESTKUNDE GmbH."
    @converter.convert
    invoice = @converter.invoices[0]
    # Rechnungsadresse ist Adresse der Rechnung
    assert invoice.invoice?
    assert invoice.address.street =~ /Kreuzbergstr/, "#{invoice.address.street} is not Kreuzbergstr."
    assert invoice.address.company =~ /Versandfirma/, "#{invoice.address.company} is not Versandfirma."
    assert invoice.address.fullname =~ /Peter/, "#{invoice.address.fullname} is not Peter."
    delivery_note= invoice.delivery_note
    assert delivery_note && delivery_note.delivery_note?, "Delivery note missing, eventually not converted yet."
    # Lieferadresse ist Adresse des Lieferscheins
    street = delivery_note.address.street
    assert_match street, /Kreuzbergstr/, "#{street} is not Kreuzbergstrasse."
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
