require 'rake'                                                                                                                                       
require 'rake/testtask'                                                                                                                              
require 'rake/rdoctask'                                                                                                                              
require 'rake/gempackagetask'                                                                                                                        
                                                                                                                                                     
desc 'Default: run unit tests.'                                                                                                                      
task :default => :test                                                                                                                               
                                                                                                                                                     
desc 'Test the request_routing plugin.'                                                                                                              
Rake::TestTask.new(:test) do |t|                                                                                                                     
  t.libs << 'lib'                                                                                                                                    
  t.pattern = 'test/**/*_test.rb'                                                                                                                    
  t.verbose = true                                                                                                                                   
end                                                                                                                                                  
                                                                                                                                                     
desc 'Generate documentation for the Caches.rb plugin.'                                                                                      
Rake::RDocTask.new(:rdoc) do |rdoc|                                                                                                                  
  rdoc.rdoc_dir = 'rdoc'                                                                                                                             
  rdoc.title    = 'Caches.rb'                                                                                                                  
  rdoc.options << '--line-numbers' << '--inline-source'                                                                                              
  rdoc.rdoc_files.include('README')                                                                                                                  
  rdoc.rdoc_files.include('lib/**/*.rb')                                                                                                             
end

PKG_VERSION = "0.2.0"                                                                                                                                
PKG_NAME = "cachesrb"                                                                                                                                  
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"                                                                                                         
                                                                                                                                                     
PKG_FILES = FileList[                                                                                                                                
    "lib/**/*", "test/**/*", "[A-Z]*", "Rakefile", "init.rb"                                                                          
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
  s.homepage = "http://rashkovskii.com/articles/tag/caches"                                                                                                 
end                                                                                                                                                  
                                                                                                                                                     
Rake::GemPackageTask.new(spec) do |p|                                                                                                                
  p.gem_spec = spec                                                                                                                                  
  p.need_tar = true                                                                                                                                  
  p.need_zip = true                                                                                                                                  
end