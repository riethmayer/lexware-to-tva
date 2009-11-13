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
  # Sind Eigenschaften wie Zahlungsart, Zahlungsbedingungen,
  # Lieferbedingungen und Versandart nicht beim Kunden gepflegt
  # müssen diese Werte beim Auftrag übergeben werden
  def test_missing_delivery_or_pament_term_in_customer_must_be_present_in_order
    @orders.each_with_index do |order, index|
      o = Order.new(order)
      assert o.payment_mode  || o.customer.payment_method, "payment term missing for order #{o.inspect}"
      assert o.payment_code  || o.customer.payment_method, "payment method missing for order #{index}"
      assert o.shipping_code || o.customer.delivery_term, "shipping term missing for order #{o.inspect}"
      assert o.customer.delivery_method, "shipping method missing for order #{index}"
    end
  end
  # orderType muss immer 1 sein
  def test_order_type_must_be_valid
    @orders.each do |order|
      order_type = Order.new(order).order_type
      assert_equal 1, order_type, "OrderType must be set to 1 by default"
    end
  end
  # Wenn die Lieferadresse von der Rechnungsadresse abweicht, sollte
  # deliveryPrintCode=1 und invoicePrintCode=0 gesetzt werden.
  # So wird in das Packstück ein Lieferschein gelegt und die Rechnung
  # an den Kunden getrennt versendet.
  def test_assert_difference_in_delivery_and_invoice_address_triggers_delivery_notes
    @orders.each do |order|
      o = Order.new(order)
      if Address.differs?(o.customer.delivery_address, o.customer.invoice_address)
        assert ((o.delivery_print_code == 1) && (o.invoice_print_code == 0)), 'Invoice address differs from delivery address, but the invoice is packed within the delivered package'
      end
    end
  end
  # Wenn Zusatzkosten definiert sind, muessen diese in der XML als Paar auftauchen
  def test_assert_add_cost_value_is_set_only_if_add_cost_present
    @orders.each do |order|
      o = Order.new(order)
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
    order = Order.new(@orders.first)
    order.order_confirmation_id = 1337
    assert_match /<reference1>1337<\/reference1>/, order.to_xml, "reference1 must include reference_number"
  end

  def test_deliverer_id_and_order_number_will_be_concatenated_in_reference2
    order = Order.new(@orders.first)
    order.deliverer_id = '1337331'
    order.order_number = 'whatefack'
    assert_match %r{<reference2>}, order.to_xml, "reference2 must be opened"
    assert_match %r{whatefack ; 1337331}, order.to_xml, "must include deliverer_id and order_number"
    assert_match %r{</reference2>}, order.to_xml, "reference2 must be closed"
  end
end
