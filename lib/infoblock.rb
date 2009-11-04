class Infoblock
  attr_accessor :customer_id, :editor, :taxno, :attachment_no, :ustidnr, :delivered_at, :invoiced_at, :state, :entry, :segment, :fax

  def initialize(infoblock)
    { :customer_id=   => 'Kundennr',
      :editor=        => 'Bearbeiter',
      :taxno=         => 'SteuerNr',
      :attachment_no= => 'Bezugsnummer',
      :ustidnr=       => 'USTIDNR',
      :delivered_at=  => 'Lieferdatum',
      :invoiced_at=   => 'Belegdatum',
      :state=         => 'FreifeldKd1Bez',
      :entry=         => 'FreifeldKd2Bez',
      :segment=       => 'FreifeldKd3Bez',
      :fax=           => 'Fax'
    }.each do |k,v|
      self.send k, infoblock.at(v).innerHTML.strip if infoblock.at(v)
    end
    extract_attachment_no
    cleanup_taxno
  end

  def extract_attachment_no
    if /\d+/ =~ self.attachment_no
      self.attachment_no = $&.strip
    else
      self.attachment_no = nil
    end
  end

  def cleanup_taxno
    self.taxno.gsub!(/\s+/,'')
  end
end
