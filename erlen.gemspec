Gem::Specification.new do |s|
  s.name        = 'erlen'
  s.version     = '0.0.9'
  s.date        = '2016-10-21'
  s.summary     = "VALIDATE"
  s.description = "Validator and Serializer"
  s.authors     = ["Tim Brenner", "David An"]
  s.platform    = Gem::Platform::RUBY
  s.files       = Dir["lib/*"]
  s.license     = 'MIT'
  s.email       = 'engineering@hireology.com'

  #s.homepage    = 'http://rubygems.org/gems/hola'

  s.add_development_dependency "rspec"
end
