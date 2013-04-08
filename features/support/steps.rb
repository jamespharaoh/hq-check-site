Given /^a config "(.*?)":$/ do
	|name, content|
	@configs[name] = content
end

Given /^(?:one|another) server which responds in (\d+) seconds?$/ do
	|time_str|

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: "200",
		response_time: time_str.to_i,
		response_body: "",
	}

	$servers[server[:address]] = server

end

Given /^(?:one|another) server which responds with "(.*?)"$/ do
	|response_str|

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: "200",
		response_time: 0,
		response_body: response_str,
	}

	$servers[server[:address]] = server

end

Given /^(?:one|another) server which responds with (\d+) "(.*?)"$/ do
	|status_str, response_str|

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: status_str,
		response_time: 0,
		response_body: response_str,
	}

	$servers[server[:address]] = server

end

Given /^(?:one|another) server which requires username "([^"]*)" and password "([^"]+)"$/ do
	|username, password|

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: "200",
		response_time: 0,
		response_body: "",
		auth_method: :http,
		auth_username: username,
		auth_password: password,
	}

	$servers[server[:address]] = server

end

Given /^one server which requires form based login with "([^"]*)" and "([^"]*)"$/ do
	|username, password|

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: "200",
		response_time: 0,
		response_body: "",
		auth_method: :form,
		auth_username: username,
		auth_password: password,
	}

	$servers[server[:address]] = server

end

Given /^one server which requires header based login$/ do

	server = {
		address: "127.0.1.#{$servers.size}",
		request_count: 0,
		response_code: "200",
		response_time: 0,
		response_body: "",
		auth_method: :headers,
		auth_username: "USER",
		auth_password: "PASS",
	}

	$servers[server[:address]] = server

end

When /^check\-site is run with config "([^"]*)"$/ do
	|config_name|

	Resolv.stub(:getaddresses).and_return(
		$servers.values.map {
			|server| server[:address]
		}
	)

	@script =
		HQ::CheckSite::Script.new

	@script.stdout = StringIO.new
	@script.stderr = StringIO.new

	Tempfile.open "check-site-script-" do
		|temp|

		config_str = @configs[config_name]
		config_str.gsub! "${port}", $web_config[:Port].to_s
		config_doc = XML::Document.string config_str
		temp.write config_doc
		temp.flush

		@script.args = [
			"--config", temp.path,
		]

		@script.main

	end

end

Then /^all servers should receive page requests$/ do
	$servers.each do
		|server_address, server|
		server[:request_count].should >= 1
	end
end

Then /^the status should be (\d+)$/ do
	|status_str|
	@script.status.should == status_str.to_i
end

Then /^the message should be "(.*?)"$/ do
	|message|
	@script.stdout.string.strip.should == message
end
