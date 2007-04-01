require 'rake'                                                                                                                                       
require 'spec/rake/spectask'
require 'rake/rdoctask'                                                                                                                              
require 'rake/gempackagetask'                                                                                                                        
                                                                                                                                                     
desc 'Default: run unit tests.'                                                                                                                      
task :default => :spec                                                                                                                               
                                                                                                                                                     
                                                                                                                                                     
desc 'Generate documentation for the Caches.rb plugin.'                                                                                      
Rake::RDocTask.new(:rdoc) do |rdoc|                                                                                                                  
  rdoc.rdoc_dir = 'rdoc'                                                                                                                             
  rdoc.title    = 'Caches.rb'                                                                                                                  
  rdoc.options << '--line-numbers' << '--inline-source'                                                                                              
  rdoc.rdoc_files.include('README')                                                                                                                  
  rdoc.rdoc_files.include('lib/**/*.rb')                                                                                                             
end

PKG_VERSION = "0.4.0"                                                                                                                                
PKG_NAME = "cachesrb"                                                                                                                                  
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"                                                                                                         
                                                                                                                                                     
PKG_FILES = FileList[                                                                                                                                
    "lib/**/*", "spec/**/*", "[A-Z]*", "Rakefile", "init.rb"                                                                          
].exclude(/\bCVS\b|~$|\.svn/)

spec = Gem::Specification.new do |s|                                                                                                                 
  s.name = PKG_NAME                                                                                                                                  
  s.version = PKG_VERSION                                                                                                                            
  s.summary = "Caches.rb -- simple Ruby method caching"                                                                  
  s.has_rdoc = true                                                                                                                                  
  s.files = PKG_FILES                                                                                                                                
                                                                                                                                                     
  s.require_path = 'lib'                                                                                                                             
  s.autorequire  = 'caches'                                                                                                                          
  s.author = "Yurii Rashkovskii"                                                                                                                         
  s.email = "yrashk@verbdev.com"                                                                                                                      
  s.homepage = "http://pad.verbdev.com/cachesrb"
  s.rubyforge_project = "cachesrb"         
  s.add_dependency 'activesupport'
end                                                                                                                                                  
                                                                                                                                                     
Rake::GemPackageTask.new(spec) do |p|                                                                                                                
  p.gem_spec = spec                                                                                                                                  
  p.need_tar = true                                                                                                                                  
  p.need_zip = true                                                                                                                                  
end

desc "Run all specifications"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/*.rb']
end