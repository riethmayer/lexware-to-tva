# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), 'test_helper')

class CustomerTest < Test::Unit::TestCase

  FILES    = File.join(File.dirname(__FILE__), "data")
  TESTFILE = File.join(FILES, "input", "all.xml")

  def setup
    @converter = Converter.new(FILES)
    @customer ||= @converter.import_orders_from(TESTFILE)
  end

  def test_all_customers_have_an_id
    @customer.each do |customer|
      assert Customer.new(customer).id
    end
    assert_match /1/, Customer.new(@customer.first).id
  end
  #
  # default values
  #
  def test_default_currency_should_be_euro_for_all_customers
    @customer.each do |customer|
      assert_equal 1, Customer.new(customer).currency_code
    end
  end

  def test_default_language_should_be_german_for_all_customers
    @customer.each do |customer|
      assert_equal 0, Customer.new(customer).language_id
    end
  end

  def test_default_delivery_country_code_should_be_germany
    c = Customer.new(@customer.first)
    assert_equal 41, c.delivery_address.country.code
  end

  def test_default_invoice_country_code_should_be_germany
    c = Customer.new(@customer.first)
    assert_equal 49, c.invoice_address.country.code
  end

  def test_customer_has_invoice_address
    c = Customer.new(@customer.first)
    assert c.invoice_address
    assert c.invoice_address.zipcode
    assert_match /10997/, c.invoice_address.zipcode
    assert_match /Schlesische Str. 4/, c.invoice_address.street
    assert_match /Herr/, c.invoice_address.salutation
    assert_equal 49, c.invoice_address.country.code
  end

  def test_customer_has_deliver_address
    c = Customer.new(@customer.first)
    assert c.delivery_address
    assert c.delivery_address.zipcode
    assert_match /10999/, c.delivery_address.zipcode
    assert_match /Schlesische Str. 14/, c.delivery_address.street
    assert_match /2. OG, Mitte/, c.delivery_address.addition
    assert_equal 41, c.delivery_address.country.code
  end

  def test_customer_to_xml_works
    c = Customer.new(@customer.first)
    file = File.join(File.dirname(__FILE__), "data", "customer.xml")
    File.open(file, 'w') {|f| f.write(c.to_xml) }
  end

  def test_customer_from_germany_with_ustid_pays_taxes
    customer = Customer.new(@customer.first)
    assert german_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_germany_without_ustid_pays_taxes
    customer = Customer.new(@customer.first)
    assert german_customer(without_ustid(customer, nil)).pays_taxes?
    assert german_customer(without_ustid(customer, "")).pays_taxes?
  end

  def test_customer_from_eu_without_ustid_pays_taxes
    customer = Customer.new(@customer.first)
    assert european_customer(without_ustid(customer)).pays_taxes?
  end

  def test_customer_from_eu_with_ustid_pays_no_taxes
    customer = Customer.new(@customer.first)
    assert_equal false, european_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_with_ustid_pays_no_taxes
    customer = Customer.new(@customer.first)
    assert_equal false, american_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_without_ustid_pays_no_taxes
    customer = Customer.new(@customer.first)
    assert_equal false, american_customer(without_ustid(customer)).pays_taxes?
  end

  def test_invoice_address_in_germany_but_delivery_address_in_eu_and_with_ustid_pays_no_taxes
    customer = Customer.new(@customer.first)
    customer = german_customer(with_ustid(customer))
    customer.delivery_address.country.code = 43
    customer.delivery_address.country.name = "Österreich"
    assert_equal false, customer.pays_taxes?
  end

  def test_delivery_address_in_germany_but_invoice_address_in_eu_and_with_ustid_pays_no_taxes
    customer = Customer.new(@customer.first)
    customer = german_customer(with_ustid(customer))
    customer.invoice_address.country.code = 43
    customer.invoice_address.country.name = "Österreich"
    assert_equal true, customer.pays_taxes?
  end

  # helper files for testing
  def german_customer(customer)
    customer.delivery_address.country.code = 49
    customer.delivery_address.country.name = "Deutschland"
    customer.invoice_address.country.code  = 49
    customer.invoice_address.country.name  = "Deutschland"
    customer
  end

  def european_customer(customer)
    customer.invoice_address.country.code  = 43
    customer.invoice_address.country.name  = "Österreich"
    customer.delivery_address.country.code = 43
    customer.delivery_address.country.name = "Österreich"
    customer
  end

  def american_customer(customer)
    customer.invoice_address.country.code  = 50
    customer.invoice_address.country.name  = "USA"
    customer.delivery_address.country.code = 50
    customer.delivery_address.country.name = "USA"
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
