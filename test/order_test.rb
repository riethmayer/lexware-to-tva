# -*- coding: utf-8 -*-
require File.dirname(__FILE__) +  '/test_helper'
class CustomerTest < Test::Unit::TestCase

  def setup
    file = File.join(File.dirname(__FILE__), "data", "input","all.xml")
    @converter = Converter.new
    @order ||= @converter.import_orders_from(file).first
  end

  def test_ordernumber_should_be_in_field_referenz_1
    assert true
  end

  def test_order_type_must_be_valid
    assert true
  end

  def test_delivery_print_code_controls_delivery_note
    assert true
  end

  def test_assert_difference_in_delivery_and_invoice_address_triggers_delivery_notes
    assert true
  end

  def test_assert_add_cost_value_is_set_only_if_add_cost_present
    assert true
  end

  def test_number_of_positions_for_one_position
    assert true
  end

  def test_number_of_positions_for_two_positions
    assert true
  end

  def test_number_of_positions_for_max_positions
    assert true
  end

  def test_nbl_is_set_properly
    assert true
  end

  def test_netto_for_is_set_properly
    assert true
  end

  def test_total_for_is_set_properly
    assert true
  end

  def test_to_xml_produces_valid_xml
    assert true
  end

  def test_taxes_are_set_properly
    assert true
  end

  def test_tax_extraction_works_fine
    assert true
  end

  def test_order_must_have_related_numbers_for_delivery_note_and_related_invoice
    # oversea pro artikelnummer ??
    # xml vom lieferschein muss mit uebergeben werden
    # in der bezugsnummer steht die rechnungs-nummer.
    # die nummer an sich muss nicht uebergeben werden.
    # belegnummer des auftrags im freifeld
    # belegnummer = bezugnummer
    # auftragsbest, liefer, rechnung
    # rechnung bezieht sich auf liefer
    # liefer bezieht sich auf auftrag

    assert true
  end

  def test_tax_in_order_overrides_taxcode_in_customer
    assert true
  end

  def test_truth
    assert true
  end


end
