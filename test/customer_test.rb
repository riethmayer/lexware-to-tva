require File.dirname(__FILE__) +  '/test_helper'

class CustomerTest < Test::Unit::TestCase
  def test_valid_customer
    c = Customer.new(1, 2)
    assert c
    assert_equal 1, c.customer_id
  end
  #
  # default values
  #
  def test_default_currency_should_be_euro
    c = Customer.new(1)
    assert c.currency_code = 1 # 1 is EUR according to TLV excel sheet
  end

  def test_default_language_should_be_german
    c = Customer.new(1, 2)
    assert c.language_id = 0 # 0 is german according to TLV excel sheet
  end

  def test_default_delivery_country_code_should_be_germany
    c = Customer.new(1, 2)
    assert c.delivery_country_code = 49
  end

  def test_default_invoice_country_code_should_be_germany
    c = Customer.new(1, 2)
    assert c.invoice_country_code = 49
  end
end
