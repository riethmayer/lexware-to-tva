task :default => :test

desc "Runs tests suite"
task :test do
  require File.join(File.dirname(__FILE__), 'test','all_tests.rb')
end

desc "Converts XML-File stored in input to XML-Files valid for TVA in the output directory"
task :convert do
  puts "todo"
end

desc "Installs all gems to this project"
task :install do
  puts "installing hpricot, mocha and factory_girl"
  `gem install hpricot mocha factory_girl`
end

desc "Deletes temporary files"
task :cleanup do
  puts "cleaning up tmp/conversions"
  FileUtils.rm_rf("./tmp/conversions/")
end
