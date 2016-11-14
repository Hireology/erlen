Gem::Specification.new do |s|
  s.name        = 'erlen'
  s.version     = '0.0.8'
  s.date        = '2016-10-21'
  s.summary     = "VALIDATE"
  s.description = "Validator and Serializer"
  s.authors     = ["Tim Brenner", "David An"]
  s.platform    = Gem::Platform::RUBY
  s.files       = Dir["lib/*"]

  #s.email       = 'nick@quaran.to'
  #s.homepage    = 'http://rubygems.org/gems/hola'
  #s.license     = 'MIT'

  s.add_development_dependency "rspec"
end
