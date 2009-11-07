class Order
  attr_accessor :positions, :customer, :nbl, :netto, :taxes, :total, :id

  def initialize(order)
    self.customer  = Customer.new(order)
    self.positions = positions_for(order)
    self.taxes     = Taxes.new(order)
    self.nbl       = nbl_for(order)
    self.netto     = netto_for(order)
    self.total     = total_for(order)
  end

  def type
    "Order"
  end

  def positions_for(order)
    positions = []
    (order/:Auftragspos).each do |position|
      positions << Item.new(position)
    end
  end

  def nbl_for(order)
    self.nbl = order.at('NBL').innerHTML.strip
   end

  def netto_for(order)
    self.netto = order.at('GesamtNetto').innerHTML.strip
  end

  def total_for(order)
    self.total = order.at('Gesamtbetrag').innerHTML.strip
  end

  def to_xml
    return <<-XML
<?xml version='1.0' encoding="UTF-8" ?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Item.xsd">
  <item>
    <currency>EUR</currency>
    <dispoCode>3</dispoCode>
    <grossPrice1>39.90</grossPrice1>
    <grossPrice2>0</grossPrice2>
    <itemId>4802</itemId>
    <languageId>0</languageId>
    <locked>0</locked>
    <netPrice1>0</netPrice1>
    <netPrice2>0</netPrice2>
    <quantityUnitCode>1</quantityUnitCode>
    <shortTitle>Mein Kurztitel</shortTitle>
    <taxCode>1</taxCode>
    <title>Mein Titel</title>
    <valid>true</valid>
  </item>
</Root>
XML
  end

  # TODO check whether it's possible to have multiple tax positions for one order
  class Taxes
    attr_accessor :all

    def initialize(order)
      self.all = []
      (order/:Steuersatz).each do |tax_set|
        self.all << Tax.new(tax_set)
      end
    end
  end

  class Tax
    attr_accessor :percent, :pretax, :tax
    def initialize(tax_set)
      self.percent = tax_set.at('SteuernAusgabeNBL').innerHTML.strip if tax_set.at('SteuernAusgabeNBL')
      self.pretax  = tax_set.at('SteuernAusgabe').innerHTML.strip if tax_set.at('SteuernAusgabe')
      self.tax     = tax_set.at('AusgabeSteuerBetrag').innerHTML.strip if tax_set.at('AusgabeSteuerBetrag')
    end
  end


end
