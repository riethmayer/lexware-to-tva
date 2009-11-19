# rabatte fuer privatkunden werden schon so als festpreis uebergeben
require 'bigdecimal'

class Item
  attr_accessor :grossprice_1, :grossprice_2, :netprice_1, :netprice_2 # money stuff
  attr_accessor :id, :tax_code, :title, :short_title, :quantity, :errors, :position_number # properties
  attr_accessor :language_id, :locked, :valid, :currency, :dispocode, :quantity_unit_code #defaults

  def initialize(order)

    {
      :id= => 'Artikel_NR',
      :title= => 'Artikel_Text',
      :short_title= => 'Artikel_Text',
      :grossprice_1= => 'Artikel_EZP',
      :netprice_1= => 'Artikel_EZP',
      :quantity= => 'Menge',
      :position_number= => 'PositionNr',
      :tax_code= => 'Ust-Proz'
    }.each do |k, v|
      self.send k, Converter.xml_get(v,order)
    end
    self.language_id= 0
    self.locked= 0
    self.valid= true
    self.currency= 'EUR'
    self.dispocode= 0
    self.quantity_unit_code=1
    self.grossprice_2= 0
    self.netprice_2= 0
    self.quantity     = Converter.convert_value(self.quantity)
    self.grossprice_1 = Converter.convert_value(self.grossprice_1)
    self.netprice_1   = Converter.convert_value(self.netprice_1) || '0.00'
    self.tax_code     = Converter.convert_value(self.tax_code)   || '0.00'
    calculate_grossprice_1
    self.errors = []
    # need taxcode
    if self.tax_code == '0.00'
      self.tax_code = 0
    elsif self.tax_code == '7.00'
      self.tax_code = 2
    else
      self.tax_code = 1 # 19%
    end
    # 40 chars restriction
    self.short_title = self.short_title[0..39]
    self.title = self.title[0..39]
  end

  # steuersatz aus dem artikel (ist bindend)
  def calculate_grossprice_1
    if(self.tax_code == '0.00')
      # do nothing, netprice is grossprice, as tax is 0
    else
      taxs = self.tax_code
      nets = self.netprice_1
      tax     = BigDecimal.new(taxs)
      tax     = (tax / 100) + 1
      net     = BigDecimal.new(nets)
      amount  = net * tax
      rounded = (amount * 100).round / 100
      display = rounded.to_f.to_s
      display = "#{display}0" unless display =~ /\.(\d\d)/
      self.grossprice_1 = display
    end
  end

  def truncated_title
    titles = self.title.split(' ')
    result = []
    bucket = 0
    for title in titles
      if result[bucket].nil?
        result[bucket] = title
      else
        if [result[bucket],title].join(" ").length > 40
          bucket += 1
          result[bucket] = title
        else
          result[bucket] = [result[bucket],title].join(" ")
        end
      end
    end
    result
  end

  def valid?
    errors << "Currency invalid"    if self.currency != 'EUR'
    errors << "DispoCode invalid"   if self.dispocode != 0
    errors << "GrossPrice1 missing" if self.grossprice_1.nil?
    errors << "GrossPrice2 invalid" if self.grossprice_2 != 0
    errors << "ItemId missing"      if self.id.nil?
    errors << "LanguageID invalid"  if self.language_id != 0
    errors << "Locked-Flag invalid" if self.locked != 0
    errors << "NetPrice1 missing"   if self.netprice_1.nil?
    errors << "NetPrice2 invalid"   if self.netprice_2 != 0
    errors << "QuantityUnitCode invalid" if self.quantity_unit_code != 1
    errors << "ShortTitle missing" if self.short_title.nil? or self.short_title == ""
    errors << "TaxCode invalid"    if self.tax_code.nil? or self.tax_code == ""
    errors << "Title missing"      if self.title.nil? or self.title == ""
    errors.length == 0
  end

  def type
    "Item"
  end

  def xml_partial
    partial =  <<-PARTIAL

<position>
  <grossPrice>#{self.grossprice_1}</grossPrice>
  <itemId>#{self.id}</itemId>
  <orderedQuantity>#{self.quantity}</orderedQuantity>
  <quantityUnitCode>#{self.quantity_unit_code}</quantityUnitCode>
</position>
PARTIAL
    if self.grossprice_1 && self.id && self.quantity
      return partial
    else
      return ""
    end
  end

  def xml_title_descriptions
    titles = self.truncated_title[1..3]
    result = []
    titles.each_with_index do |title,index|
      result << "<description#{index+2}><CDATA[#{title}]]></description#{index+2}>"
    end
    result.join("\n")
  end

  def to_xml
   return <<-XML
<?xml version='1.0' encoding="UTF-8" ?>
<Root xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="file:///Item.xsd">
  <item>
    <currency>#{self.currency}</currency>
    <dispoCode>#{self.dispocode}</dispoCode>
    <grossPrice1>#{self.grossprice_1}</grossPrice1>
    <grossPrice2>#{self.grossprice_2}</grossPrice2>
    <itemId>#{self.id}</itemId>
    <languageId>#{self.language_id}</languageId>
    <locked>#{self.locked}</locked>
    <netPrice1>#{self.netprice_1}</netPrice1>
    <netPrice2>#{self.netprice_2}</netPrice2>
    <quantityUnitCode>#{self.quantity_unit_code}</quantityUnitCode>
    <shortTitle><[CDATA[#{self.short_title}]]></shortTitle>
    <taxCode>#{self.tax_code}</taxCode>
    <title><[CDATA[#{self.truncated_title[0]}]]></title>#{xml_title_descriptions}
    <valid>#{self.valid? ? 'true' : 'false' }</valid>
  </item>
</Root>
XML
  end
end
