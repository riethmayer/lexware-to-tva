class Customer
  # mandatory fields for customer.xsd
  attr_accessor :customer_id, :currency_code
  # additional mandatory fields for german business customers
  attr_accessor :delivery_country_code, :invoice_country_code, :language_id
  # there are no additional mandatory fields for other customers
  # if there's no address for the customer, the order must have the address
  # if there's only an invoice address, this will be the deliveryaddress
  # If one of the following datafields is missing within the customer:
  #    * terms and methods of payment
  #    * terms and methods of delivery
  # these fields have to be provided within the order.
  attr_accessor :invoice_address, :delivery_address
  attr_accessor :payment_term, :payment_method, :delivery_term, :delivery_method, :inclusive_taxes

  def initialize(cid, currency = 1, delivery_cc = 49, invoice_cc = 49, language = 0, opts = {})
    self.customer_id           = cid
    self.currency_code         = currency
    self.delivery_country_code = delivery_cc
    self.invoice_country_code  = invoice_cc
    self.language_id           = language
    self.invoice_address       = opts[:invoice_address]
    self.delivery_address      = opts[:delivery_address]
    self.payment_term          = opts[:payment_term]
    self.delivery_term         = opts[:delivery_term]
    self.delivery_method       = opts[:delivery_method]
    self.inclusive_taxes       = opts[:inclusive_taxes] # fSteuerbar? #FIXME
  end

  def to_xml
    return <<-XML
<?xml version="1.0" encoding="UTF-8"?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Customer.xsd">
<customer>
  <currencyCode>#{self.currency_code}</currencyCode>
  <customerId>#{self.customer_id}</customerId>
  <deliveryAddress1>#{self.company}</deliveryAddress1>
  <deliveryAddress2>#{self.fullname}</deliveryAddress2>
  <deliveryAddress3>#{self.delivery_address.addition}</deliveryAddress3>
  <deliveryCountryCode>#{self.delivery_country_code}</deliveryCountryCode>
  <deliveryPlace>#{self.delivery_address.place}</deliveryPlace>
  <deliveryStreet>#{self.delivery_address.street}</deliveryStreet>
  <deliveryTermsCode>#{delivery_term}</deliveryTermsCode>
  <deliveryZipCode>#{self.delivery_address.zipcode}</deliveryZipCode>
  <grossPriceCode>#{self.inclusive_taxes}</grossPriceCode>
  <invoiceAddress1>#{self.address.salutation}</invoiceAddress1>
  <invoiceAddress2>#{self.fullname}</invoiceAddress2>
  <invoiceAddress3>#{self.address.addition}</invoiceAddress3>
  <invoiceCountryCode>#{self.invoice_country_code}</invoiceCountryCode>
  <invoicePlace>#{self.address.place}</invoicePlace>
  <invoiceStreet>#{self.address.street}</invoiceStreet>
  <invoiceZipCode>#{self.address.zipcode}</invoiceZipCode>
  <languageId>#{self.language_id}</languageId>
</customer>
</Root>
XML
  end
end
