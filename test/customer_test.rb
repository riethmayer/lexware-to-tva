require File.dirname(__FILE__) +  '/test_helper'

class CustomerTest < Test::Unit::TestCase

  def setup
    file = File.join(File.dirname(__FILE__), "data", "all.xml")
    @customer ||= Converter.import_orders_from(file).first
  end

  def test_valid_customer
    c = Customer.new(@customer)
    assert c
    assert_match /1/, c.customer_id
  end
  #
  # default values
  #
  def test_default_currency_should_be_euro
    c = Customer.new(@customer)
    assert_equal 1, c.currency_code
  end

  def test_default_language_should_be_german
    c = Customer.new(@customer)
    assert_equal 0, c.language_id
  end

  def test_default_delivery_country_code_should_be_germany
    c = Customer.new(@customer)
    assert_equal 41, c.delivery_country_code
  end

  def test_default_invoice_country_code_should_be_germany
    c = Customer.new(@customer)
    assert_equal 49, c.invoice_country_code
  end

  def test_customer_has_invoice_address
    c = Customer.new(@customer)
    assert c.invoice_address
    assert c.invoice_address.zipcode
    assert_match /10589/, c.invoice_address.zipcode
    assert_match /Mindener Str. 20/, c.invoice_address.street
    assert_match /Herr/, c.invoice_address.salutation
    assert_equal 49, c.invoice_address.country
  end

  def test_customer_has_deliver_address
    c = Customer.new(@customer)
    assert c.delivery_address
    assert c.delivery_address.zipcode
    assert_match /12334/, c.delivery_address.zipcode
    assert_match /Liefer Strasse 19/, c.delivery_address.street
    assert_match /2. OG, Mitte/, c.delivery_address.addition
    assert_equal 41, c.delivery_address.country
  end

  def test_customer_to_xml_works
    c = Customer.new(@customer)
    file = File.join(File.dirname(__FILE__), "data", "customer.xml")
    File.open(file, 'w') {|f| f.write(c.to_xml) }
  end
end
