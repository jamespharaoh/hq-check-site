#!/usr/bin/env ruby

hq_project_dir =
	File.expand_path "..", __FILE__

hq_project_name =
	File.basename hq_project_dir

$LOAD_PATH.unshift "#{hq_project_dir}/ruby" \
	unless $LOAD_PATH.include? "#{hq_project_dir}/ruby"

Gem::Specification.new do
	|spec|

	spec.name = hq_project_name
	spec.version = "0.3.0"
	spec.platform = Gem::Platform::RUBY
	spec.authors = [ "James Pharaoh" ]
	spec.email = [ "james@phsys.co.uk" ]
	spec.homepage = "https://github.com/jamespharaoh/#{hq_project_name}"
	spec.summary = "HQ check site script"
	spec.description = "HQ nagios plugin to check a web site"
	spec.required_rubygems_version = ">= 1.3.6"

	spec.rubyforge_project = hq_project_name

	spec.add_dependency "hq-tools", ">= 0.4.2"
	spec.add_dependency "libxml-ruby", ">= 2.6.0"

	spec.add_development_dependency "cucumber", ">= 1.2.1"
	spec.add_development_dependency "rake", ">= 10.0.3"
	spec.add_development_dependency "rspec", ">= 2.12.0"
	spec.add_development_dependency "rspec_junit_formatter"
	spec.add_development_dependency "simplecov"

	spec.files = Dir[
		"lib/**/*.rb",
	]

	spec.test_files = Dir[
		"features/**/*.feature",
		"features/**/*.rb",
		"spec/**/*-spec.rb",
	]

	spec.executables =
		Dir.new("bin").entries - [ ".", ".." ]

	spec.require_paths = [ "lib" ]

end

