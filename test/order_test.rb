# -*- encoding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class OrderTest < Test::Unit::TestCase

  FILES    = File.join(FileUtils.pwd, "test","data", "input")

  def make_file(str)
    File.join(FILES,"#{str}.xml")
  end

  def setup
    @order         = Factory(:order)
    @delivery_note = Factory(:delivery_note)
    @invoice       = Factory(:invoice)
  end

  def test_each_order_has_an_invoice_and_a_delivery_note_after_convert
    converter = Converter.new(make_file('111_items'))
    converter.convert
    orders    = converter.invoices
    orders.each do |o|
      assert o.id && o.delivery_note_id, "neither id nor delivery note id set"
    end
  end

  # Sind Eigenschaften wie Zahlungsart, Zahlungsbedingungen,
  # Lieferbedingungen und Versandart nicht beim Kunden gepflegt
  # müssen diese Werte beim Auftrag übergeben werden
  def test_missing_delivery_or_pament_term_in_customer_must_be_present_in_order
    converter = Converter.new(make_file('111_items'))
    converter.convert
    orders    = converter.invoices
    orders.each_with_index do |o, index|
      assert o.customer.payment_mode, "payment term missing for order #{o.id}"
      assert o.customer.payment_code, "payment method missing for order #{o.id}"
      assert o.customer.shipping_code, "shipping method missing for order #{o.id}"
      assert o.customer.delivery_terms_code, "shipping terms missing for order #{o.id}"
    end
  end

  # orderType muss immer 1 sein
  def test_order_type_must_be_valid
    converter = Converter.new(make_file('111_items'))
    converter.convert
    orders    = converter.invoices
    orders.each do |order|
      order_type = order.order_type
      assert_equal "<orderType>1</orderType>", order_type, "OrderType must be set to 1 by default"
    end
  end
  # Wenn die Lieferadresse von der Rechnungsadresse abweicht, sollte
  # deliveryPrintCode=1 und invoicePrintCode=0 gesetzt werden.
  # So wird in das Packstück ein Lieferschein gelegt und die Rechnung
  # an den Kunden getrennt versendet.
  def test_assert_difference_in_delivery_and_invoice_address_triggers_delivery_notes
    invoice_address  = Factory(:invoice_address, :street => "Österreichische Strasse")
    delivery_address = Factory(:delivery_address)
    @invoice.delivery_note = @delivery_note
    @invoice.address = invoice_address
    @invoice.delivery_note.address = invoice_address
    @invoice.update_invoice_print_code
    assert @invoice.invoice_print_code == "1", "InvoicePrintCode should be 1 if #{@invoice.address.street} equals #{@invoice.delivery_note.address.street}"

    @invoice.delivery_note.address = delivery_address
    @invoice.update_invoice_print_code
    assert @invoice.invoice_print_code == "0", "InvoicePrintCode should be 0 if #{@invoice.address.street} is different than #{@invoice.delivery_note.address.street}"
  end
  # Wenn Zusatzkosten definiert sind, muessen diese in der XML als Paar auftauchen
  def test_assert_add_cost_value_is_set_only_if_add_cost_present
    converter = Converter.new(make_file('111_items'))
    converter.convert
    orders    = converter.invoices
    orders.each do |o|
      if o.add_costs?
        assert_match /addCosts1/, o.add_costs_xml
        assert_match /\d+\.\d+/, o.add_costs_xml
        assert_match /addCostsValue1/, o.add_costs_xml
      end
    end
  end
  # jede Rechnung sollte eine Auftragsbestaetigung haben mit Bezugsnummer
  # es hat sich rausgestellt, dass es Rechnungen ohne AB und ohne LS gibt.
  # def test_each_invoice_must_have_an_order_confirmation_or_delivery_note_id
  #   @orders.each do |order|
  #     o = Order.new(order)
  #     assert (o.order_confirmation_id || o.delivery_note_id), "Invoice ##{o.id} has nor order_confirmation nor delivery_note" if o.invoice?
  #   end
  # end
  # jede Rechnung sollte die Bezugsnummer in der xml unter referenz1 ausgeben
  def test_invoice_with_number_has_this_value_at_reference_1
    order = @invoice
    order.order_confirmation_id = 1337
    assert_match /<reference1><!\[CDATA\[1337\]\]><\/reference1>/, order.to_xml, "reference1 must include reference_number"
  end

  def test_deliverer_id_and_order_number_will_be_concatenated_in_reference2
    order = @invoice
    order.deliverer_id = '1337331'
    order.order_number = 'whatefack'
    assert_match %r{<reference2>}, order.to_xml, "reference2 must be opened"
    assert_match %r{whatefack ; 1337331}, order.to_xml, "must include deliverer_id and order_number"
    assert_match %r{</reference2>}, order.to_xml, "reference2 must be closed"
  end

  def test_rechnungsadresse_lieferschein_ist_lieferadresse_rechnung
    rechnung      =  Converter.new(make_file('address_update_test'))
    rechnung.convert
    lieferschein = rechnung.delivery_notes[0]
    rechnung = rechnung.invoices[0]
    assert rechnung.address, "keine Rechnungsadresse vorhanden"
    assert lieferschein, "keine Lieferscheine vorhanden"
  end

  def test_customer_has_delivery_address
    invoice = @invoice
    assert invoice.delivery_address, "There should be a delivery address after conversion"
    assert invoice.delivery_address.zipcode
    assert_match /10961/, invoice.delivery_address.zipcode
    assert_match /Lieferstrasse 1337/, invoice.delivery_address.street
    assert_equal 49, invoice.delivery_address.country.code
  end

  def test_customer_from_germany_with_ustid_pays_taxes
    invoice = @invoice
    customer = invoice.customer
    assert german_customer(with_ustid(customer)).pays_taxes?, "A german customer with ustid must pay taxes."
  end

  def test_customer_from_germany_without_ustid_pays_taxes
    invoice = @invoice
    customer = invoice.customer
    assert german_customer(without_ustid(customer, nil)).pays_taxes?
    assert german_customer(without_ustid(customer, "")).pays_taxes?
  end

  def test_customer_from_eu_without_ustid_pays_taxes
    invoice = @invoice
    customer = invoice.customer
    assert european_customer(without_ustid(customer)).pays_taxes?
  end

  def test_customer_from_eu_with_ustid_pays_no_taxes
    invoice = @invoice
    customer = invoice.customer
    assert_equal false, european_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_with_ustid_pays_no_taxes
    invoice = @invoice
    customer = invoice.customer
    assert_equal false, american_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_without_ustid_pays_no_taxes
    invoice = @invoice
    customer = invoice.customer
    assert_equal false, american_customer(without_ustid(customer)).pays_taxes?
  end

  def test_invoice_address_in_germany_but_delivery_address_in_eu_and_with_ustid_pays_no_taxes
    invoice = @invoice
    customer = invoice.customer
    customer = german_customer(with_ustid(customer))
    customer.delivery_address.country.code = 43
    customer.delivery_address.country.name = "Österreich"
    assert_equal false, customer.pays_taxes?
  end

  def test_delivery_address_in_germany_but_invoice_address_in_eu_and_with_ustid_pays_taxes
    invoice = @invoice
    customer = invoice.customer
    customer = german_customer(with_ustid(customer))
    delivery_addr = Factory(:delivery_address)
    delivery_addr.country.code = 43
    delivery_addr.country.name = "Österreich"
    invoice.delivery_note = @delivery_note
    invoice.delivery_note.address = delivery_addr
    assert invoice.customer.address.country.germany?, "Was expected to be germany, but was #{customer.address.country.name}"
    assert invoice.delivery_note.customer.address, "DeliveryAddress expected"
    assert customer.is_eu?, "European customer expected"
    assert customer.is_german?, "German customer expected"
    assert_equal true, customer.pays_taxes?, "Expected to pay taxes"
  end

  def test_invoice_has_a_company_short_name_of_maximum_10_chars
    invoice = @invoice
    assert @invoice.customer
    @invoice.customer.address.company = "aCompanyWithALoooongName"
    assert @invoice.customer.address.company.size == 24
    assert @invoice.customer.short_name.size == 10
    assert @invoice.short_name == "<shortName><![CDATA[aCompanyWi]]></shortName>", "shortName did not match #{@invoice.short_name}"
  end

  def test_invoice_has_a_company_short_name_of_maximum_10_chars
    invoice = @invoice
    assert @invoice.customer
    @invoice.customer.address.company = nil
    @invoice.customer.address.fullname = "customerWithALoooongName"
    assert @invoice.customer.address.fullname.size == 24
    assert @invoice.customer.short_name.size == 10
    assert @invoice.short_name == "<shortName><![CDATA[customerWi]]></shortName>", "shortName did not match #{@invoice.short_name}"
  end

  # helper files for testing
  def german_customer(customer)
    customer.address.country.code  = 49
    customer.address.country.name  = "Deutschland"
    if customer.delivery_address
      customer.delivery_address.country.code = 49
      customer.delivery_address.country.name = "Deutschland"
    end
    customer
  end

  def european_customer(customer)
    customer.address.country.code  = 43
    customer.address.country.name  = "Österreich"
    if customer.delivery_address
      customer.delivery_address.country.code = 43
      customer.delivery_address.country.name = "Österreich"
    end
    customer
  end

  def american_customer(customer)
    customer.address.country.code  = 50
    customer.address.country.name  = "USA"
    if customer.delivery_address
      customer.delivery_address.country.code = 50
      customer.delivery_address.country.name = "USA"
    end
    customer
  end

  def with_ustid(customer)
    customer.ustid = "DE1234567890"
    customer
  end

  def without_ustid(customer, blank_value = "")
    customer.ustid = blank_value
    customer
  end

end
