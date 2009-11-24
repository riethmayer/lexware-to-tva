class Infoblock
  attr_accessor :customer_id, :editor, :attachment_no, :ustidnr
  attr_accessor :delivered_at, :invoiced_at, :state, :entry, :segment, :fax

  def initialize(default = nil)
    self.import(default) if default
  end

  def import(infoblock)
    { :customer_id=   => 'Kundennr',
      :editor=        => 'Bearbeiter',
      :attachment_no= => 'Bezugsnummer',
      :ustidnr=       => 'KD_EG_ID_Nummer',
      :delivered_at=  => 'Lieferdatum',
      :invoiced_at=   => 'Belegdatum',
      :state=         => 'FreifeldKd1Bez',
      :entry=         => 'FreifeldKd2Bez',
      :segment=       => 'FreifeldKd3Bez',
      :fax=           => 'Fax'
    }.each do |k,v|
      self.send k, infoblock.at(v).innerHTML.strip if infoblock.at(v)
    end
    self.delivered_at = Converter.convert_date(self.delivered_at)
    self.invoiced_at  = Converter.convert_date(self.delivered_at)
    extract_attachment_no
  end

  def extract_attachment_no
    if /\d+/ =~ self.attachment_no
      self.attachment_no = $&.strip
    else
      self.attachment_no = nil
    end
  end

  def save!
  end
end
