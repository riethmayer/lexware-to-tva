# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class OrderTest < Test::Unit::TestCase

  FILES    = File.join(File.dirname(__FILE__), "data")
  TESTFILE = File.join(FILES, "input", "all.xml")

  def setup
    @converter = Converter.new(FILES)
    @orders ||= @converter.import_orders_from(TESTFILE)
  end

  def test_each_order_has_an_id_or_a_delivery_note_id
    @orders.each do |order|
      o = Order.new(order)
      assert o.id || o.delivery_note_id, "neither id nor delivery note id set"
    end
  end

  def test_ordernumber_should_be_in_field_referenz_1
    # Die Bestellnummer des Webshops sollte in das Feld „Referenz 1“ geschrieben werden
    @orders.each do |order|
      assert Order.new(order).customer.reference_number
    end
  end

  # Sind Eigenschaften wie Zahlungsart, Zahlungsbedingungen,
  # Lieferbedingungen und Versandart nicht beim Kunden gepflegt
  # müssen diese Werte beim Auftrag übergeben werden
  def test_missing_delivery_or_pament_term_in_customer_must_be_present_in_order
    @orders.each do |order|
      o = Order.new(order)
      assert o.payment_mode  || o.customer.payment_method, 'payment term missing'
      assert o.payment_code  || o.customer.payment_method, 'payment method missing'
      assert o.shipping_code || o.customer.delivery_term, 'shipping term missing'
      assert o.customer.delivery_method, 'shipping method missing'
    end
  end

  def test_order_type_must_be_valid
    # orderType darf nur die angegebenen Werte besitzen, alle anderen
    # Werte dürfen nicht verwendet werden
    @orders.each do |order|
      order_type = Order.new(order).order_type
      assert (1..12).include?(order_type), "OrderType <<#{order_type}>> unknown."
    end
  end

  def test_delivery_print_code_controls_delivery_note
    # Bei deliveryPrintCode=1 wird in das Packstück ein Lieferschein gelegt.
    # Bei invoicePrintCode=0 wird die Rechnung an den Kunden
    # separat versandt; bei invoicePrintCode=1 wird die Rechnung zu
    # der Ware in das Packstück gelegt
    assert true
  end

  def test_assert_difference_in_delivery_and_invoice_address_triggers_delivery_notes
    # Wenn die Lieferadresse von der Rechnungsadresse abweicht, sollte
    # deliveryPrintCode=1 und invoicePrintCode=0 gesetzt werden.
    # So wird in das Packstück ein Lieferschein gelegt und die Rechnung
    # an den Kunden getrennt versendet.
    @orders.each do |order|
      o = Order.new(order)
      if Address.differs?(o.customer.delivery_address, o.customer.invoice_address)
        assert ((o.delivery_print_code == 1) && (o.invoice_print_code == 0)), 'Invoice address differs from delivery address, but the invoice is packed within the delivered package'
      end
    end
  end

  def test_assert_add_cost_value_is_set_only_if_add_cost_present
    # Zusatzkosten add-cost-value1..5 werden nur berücksichtigt, wenn eine
    # zugehörige Bezeichnung add-cost mitgeliefert wird.
    # Es ist also nur eine paarige Übergabe Zusatzkostenbezeichnung
    # plus Wert zulässig.
    @orders.each do |order|
      o = Order.new(order)
      if o.add_costs?
        assert_match /addCosts1/, o.add_costs_xml
        assert_match /\d+\.\d+/, o.add_costs_xml
        assert_match /addCostsValue1/, o.add_costs_xml
      end
    end
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
    @orders.each do |order|
      assert true
    end
  end

  def test_tax_in_order_overrides_taxcode_in_customer
    assert true
  end
end
