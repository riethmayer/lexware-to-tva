require 'rubygems'
require 'hpricot'

# XML-converter for orders from laxware-faktura to TVA.
class Converter

  INPUT_DIRECTORY  =  File.join(File.dirname(__FILE__), "..", "input")
  OUTPUT_DIRECTORY =  File.join(File.dirname(__FILE__), "..", "output")

  attr_accessor :no_customers, :no_items, :no_orders
  CRITICAL = true

  # extracts a list of orders from a given file
  def self.import_orders_from(file)
    xml = File.read(file)
    doc = Hpricot::XML(xml)
    orders = []
    (doc/:Auftrag).each do |order|
      orders << order
    end
    orders
  end

  def self.convert
    files = collect_files_from_input
    files.each_with_index do |file,file_number|
      [ get_customers_from(file),
        get_items_from(file),
        get_orders_from(file)].flatten.each do |element|
        done_file = File.open(create_filename_for(element.to_xml, file_number), 'w')
        send_via_ftp(done_file)
      end
    end
    cleanup(files) unless something_went_wrong?
  end

  def self.get_customers_from(file)
    # todo
  end

  def self.get_items_from(file)
    # todo
  end

  def self.get_orders_from(file)
    # todo
  end

  def self.create_filename_for(file, file_number)
    # todo
  end

  def self.send_via_ftp(done_file)
    if valid(done_file)
      success = FTP::Send_with_basic_authentification(done_file)
      if success
        mark_for_cleanup(done_file)
      else
        mark_for_problem_report(done_file)
      end
    else
      # this shouldn't happen, but if it does, our xml data is mal formed
      # in this case we've to fix it programmatically:
      #     mail to jan@riethmayer.de
      mark_for_problem_report(done_file, CRITICAL)
    end
  end

  def self.cleanup(files)
    # todo
  end

  def self.something_went_wrong?
    # todo
  end

  def self.mark_for_cleanup(file)
    # todo
  end

  def self.mark_for_problem_report(file, critical= false)
    # todo
  end

  def self.collect_files_from_input
    files = Dir.new(INPUT_DIRECTORY).entries
    result = []
#    files.each do |file|
#      result << File.read(file)
#    end
    result
  end
end
