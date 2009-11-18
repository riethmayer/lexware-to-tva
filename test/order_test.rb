# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class OrderTest < Test::Unit::TestCase

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end

  def setup
    @converter ||= Converter.new(make_file('111_items'))
    @orders ||= @converter.invoices
  end

  def test_each_order_has_an_id_or_a_delivery_note_id
    @orders.each do |o|
      assert o.id || o.delivery_note_id, "neither id nor delivery note id set"
    end
  end
  # Sind Eigenschaften wie Zahlungsart, Zahlungsbedingungen,
  # Lieferbedingungen und Versandart nicht beim Kunden gepflegt
  # müssen diese Werte beim Auftrag übergeben werden
  def test_missing_delivery_or_pament_term_in_customer_must_be_present_in_order
    @orders.each_with_index do |o, index|
      assert o.payment_mode  || o.customer.payment_method, "payment term missing for order #{o.id}"
      assert o.payment_code  || o.customer.payment_method, "payment method missing for order #{o.id}"
      assert o.shipping_code || o.customer.delivery_term, "shipping term missing for order #{o.id}"
      assert o.customer.delivery_method, "shipping method missing for order #{o.id}"
    end
  end
  # orderType muss immer 1 sein
  def test_order_type_must_be_valid
    @orders.each do |order|
      order_type = order.order_type
      assert_equal 1, order_type, "OrderType must be set to 1 by default"
    end
  end
  # Wenn die Lieferadresse von der Rechnungsadresse abweicht, sollte
  # deliveryPrintCode=1 und invoicePrintCode=0 gesetzt werden.
  # So wird in das Packstück ein Lieferschein gelegt und die Rechnung
  # an den Kunden getrennt versendet.
  def test_assert_difference_in_delivery_and_invoice_address_triggers_delivery_notes
    @converter.convert
    orders = @converter.invoices
    orders.each do |o|
      if Address.differs?(o.address, o.delivery_note.address)
        assert ((o.delivery_print_code == 1) && (o.invoice_print_code == 0)), 'Invoice address differs from delivery address, but the invoice is packed within the delivered package'
      end
    end
  end
  # Wenn Zusatzkosten definiert sind, muessen diese in der XML als Paar auftauchen
  def test_assert_add_cost_value_is_set_only_if_add_cost_present
    @orders.each do |o|
      if o.add_costs?
        assert_match /addCosts1/, o.add_costs_xml
        assert_match /\d+\.\d+/, o.add_costs_xml
        assert_match /addCostsValue1/, o.add_costs_xml
      end
    end
  end
  # jede Rechnung sollte eine Auftragsbestaetigung haben mit Bezugsnummer
  # es hat sich rausgestellt, dass es Rechnungen ohne AB und ohne LS gibt.
  #def test_each_invoice_must_have_an_order_confirmation_or_delivery_note_id
  #  @orders.each do |order|
  #    o = Order.new(order)
  #    assert (o.order_confirmation_id || o.delivery_note_id), "Invoice ##{o.id} has nor order_confirmation nor delivery_note" if o.invoice?
  #  end
  #end
  # jede Rechnung sollte die Bezugsnummer in der xml unter referenz1 ausgeben
  def test_invoice_with__number_has_this_value_at_reference_1
    order = @orders.first
    order.order_confirmation_id = 1337
    assert_match /<reference1>1337<\/reference1>/, order.to_xml, "reference1 must include reference_number"
  end

  def test_deliverer_id_and_order_number_will_be_concatenated_in_reference2
    order = @orders.first
    order.deliverer_id = '1337331'
    order.order_number = 'whatefack'
    assert_match %r{<reference2>}, order.to_xml, "reference2 must be opened"
    assert_match %r{whatefack ; 1337331}, order.to_xml, "must include deliverer_id and order_number"
    assert_match %r{</reference2>}, order.to_xml, "reference2 must be closed"
  end
end
