require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "csv_schema"
    gem.summary = %Q{This gem validates the format of csv data for ETL tools}
    gem.description = %Q{This validator is intended to be run on csv files that are updated and received on a regular basis.  It allows you to specify required headers the following data restrictions:  columns that must be unique, columns that must be restricted to certain values, or columns that can't allow nil values.  This gem checks that the newly received file is consistent with the specified 'csv schema'.  This frees you form having to manually check that the new file has not changed and reduces the possibility that an unnoticed change will cause any subsequent analyses to be incorrect. }
    gem.email = ""
    gem.homepage = "http://github.com/jconley88/csv_schema"
    gem.authors = ["jconley"]
    gem.add_development_dependency "rspec", "~> 1.3.1"
    gem.add_dependency "fastercsv", "~> 1.5.3"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "csv_schema #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
