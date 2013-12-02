# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'agwx_biophys/version'

Gem::Specification.new do |spec|
  spec.name          = "agwx_biophys"
  spec.version       = AgwxBiophys::VERSION
  spec.authors       = ["RickWayne"]
  spec.email         = ["fewayne@wisc.edu"]
  spec.description   = %q{Biophysical calculators primarily useful in agriculture and land management}
  spec.summary       = %q{So far, just an ET calculator (Priestly-Taylor)}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
