# -*- coding: utf-8 -*-
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
    assert_equal 41, c.delivery_country.code
  end

  def test_default_invoice_country_code_should_be_germany
    c = Customer.new(@customer)
    assert_equal 49, c.invoice_country.code
  end

  def test_customer_has_invoice_address
    c = Customer.new(@customer)
    assert c.invoice_address
    assert c.invoice_address.zipcode
    assert_match /10589/, c.invoice_address.zipcode
    assert_match /Mindener Str. 20/, c.invoice_address.street
    assert_match /Herr/, c.invoice_address.salutation
    assert_equal 49, c.invoice_address.country.code
  end

  def test_customer_has_deliver_address
    c = Customer.new(@customer)
    assert c.delivery_address
    assert c.delivery_address.zipcode
    assert_match /12334/, c.delivery_address.zipcode
    assert_match /Liefer Strasse 19/, c.delivery_address.street
    assert_match /2. OG, Mitte/, c.delivery_address.addition
    assert_equal 41, c.delivery_address.country.code
  end

  def test_customer_to_xml_works
    c = Customer.new(@customer)
    file = File.join(File.dirname(__FILE__), "data", "customer.xml")
    File.open(file, 'w') {|f| f.write(c.to_xml) }
  end

  def test_customer_from_germany_with_ustid_pays_taxes
    customer = Customer.new(@customer)
    assert german_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_germany_without_ustid_pays_taxes
    customer = Customer.new(@customer)
    assert german_customer(without_ustid(customer, nil)).pays_taxes?
    assert german_customer(without_ustid(customer, "")).pays_taxes?
  end

  def test_customer_from_eu_without_ustid_pays_taxes
    customer = Customer.new(@customer)
    assert european_customer(without_ustid(customer)).pays_taxes?
  end

  def test_customer_from_eu_with_ustid_pays_no_taxes
    customer = Customer.new(@customer)
    assert_equal false, european_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_with_ustid_pays_no_taxes
    customer = Customer.new(@customer)
    assert_equal false, american_customer(with_ustid(customer)).pays_taxes?
  end

  def test_customer_from_other_countries_without_ustid_pays_no_taxes
    customer = Customer.new(@customer)
    assert_equal false, american_customer(without_ustid(customer)).pays_taxes?
  end

  def test_invoice_address_in_germany_but_delivery_address_in_eu_and_with_ustid_pays_no_taxes
    customer = Customer.new(@customer)
    customer = german_customer(with_ustid(customer))
    customer.delivery_country.code = 43
    customer.delivery_country.name = "Österreich"
    assert_equal false, customer.pays_taxes?
  end

  def test_delivery_address_in_germany_but_invoice_address_in_eu_and_with_ustid_pays_no_taxes
    customer = Customer.new(@customer)
    customer = german_customer(with_ustid(customer))
    customer.invoice_country.code = 43
    customer.invoice_country.name = "Österreich"
    assert_equal false, customer.pays_taxes?
  end

  # helper files for testing
  def german_customer(customer)
    customer.delivery_country.code = 49
    customer.delivery_country.name = "Deutschland"
    customer.invoice_country.code  = 49
    customer.invoice_country.name  = "Deutschland"
    customer
  end

  def european_customer(customer)
    customer.invoice_country.code  = 43
    customer.invoice_country.name  = "Österreich"
    customer.delivery_country.code = 43
    customer.delivery_country.name = "Österreich"
    customer
  end

  def american_customer(customer)
    customer.invoice_country.code  = 50
    customer.invoice_country.name  = "USA"
    customer.delivery_country.code = 50
    customer.delivery_country.name = "USA"
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
