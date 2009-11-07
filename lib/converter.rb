require 'rubygems'
require 'hpricot'
require 'yaml'

class Converter

  attr_accessor :base, :config, :input_dir, :output_dir, :errors
  attr_accessor :files, :directory

  BASE      = File.join(File.dirname(__FILE__), "..")
  CONFIG    = YAML.load_file(File.join(BASE, "config", "config.yml"))

  def initialize(directory)
    self.directory  = directory || BASE
    self.input_dir  = File.join(self.directory, "input")
    self.output_dir = File.join(self.directory, "output")
    self.files = []
  end
  def convert
    collect_files
    self.files.each_with_index do |file, file_number|
      [ get_customers_from(file),
        get_items_from(file),
        get_orders_from(file)
      ].flatten.each_with_index do |element, element_number|
        save_as_xml(element, file_number, element_number)
      end
    end
    cleanup_files
  end

  def collect_files
    file_names = Dir.new(self.input_dir).entries - [".",".."]
    file_names.each do |file_name|
      self.files << File.join(self.input_dir,file_name)
    end
  end

  def get_customers_from(file)
    customers = []
    import_orders_from(file).each do |order|
      customers << Customer.new(order)
    end
    customers
  end

  def get_items_from(file)
    items = []
    import_orders_from(file).each do |order|
      items << Item.new(order) # may return an array
    end
    uniquify(items.flatten.compact)
  end

  def get_orders_from(file)
    orders = []
    import_orders_from(file).each do |order|
      orders << Order.new(order)
    end
    orders
  end

   # returns hpricot elements
  def import_orders_from(file)
    xml = File.read(file)
    doc = Hpricot::XML(xml)
    orders = []
    (doc/:Auftrag).each do |order|
      orders << order
    end
    orders
  end

  def uniquify(items)
    unique_items = { }
    items.each do |item|
      unique_items[item.id] = item
    end
    unique_items.values
  end

  def save_as_xml(element, file_number, element_number)
    File.open(create_filename_for(element, file_number, element_number), 'w') do |f|
      f.write(element.to_xml)
    end
  end

  def create_filename_for(element, file_number, element_number)
    File.join(self.output_dir, "#{element.type}_#{element.id}_#{file_number}_#{element_number}.xml")
  end

  def cleanup_files
   # Dir.new(self.directory).entries.each do |file|
   #   FileUtils.rm(File.join(self.directory, file)) if file =~ /\.xml$/
   # end
  end
end
