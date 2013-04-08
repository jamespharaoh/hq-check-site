require "net/http"
require "net/https"
require "resolv"
require "set"
require "webrick"
require "xml"

require "hq/tools/check-script"
require "hq/tools/getopt"

module HQ
module CheckSite
class Script < Tools::CheckScript

	# this hack allows us to make Net::HTTP connect to a specific address, while
	# using another address for other purposes, namely the host header and the
	# ssl certificate verification (i am not proud of this)

	# basically, we hijack the call to TCPSocket.open from Net::HTTP.connect,
	# and modify the first parameter (the address) to the value provided as
	# override_address

	class CustomHTTP < Net::HTTP
		attr_writer :override_address
		module CustomSocket
			def self.override_address= arg
				@override_address = arg
			end
			def self.open address, *args
				return TCPSocket.open @override_address, *args
			end
		end
		def connect *args
			begin
				Net::HTTP.const_set "TCPSocket", CustomSocket
				CustomSocket.override_address = @override_address
				return super *args
			ensure
				Net::HTTP.send :remove_const, "TCPSocket"
			end
		end
	end

	def initialize
		super
		@name = "Site"
	end

	def process_args

		@opts, @args =
			Tools::Getopt.process @args, [

				{ :name => :config,
					:required => true },

				{ :name => :debug,
					:boolean => true },

			]

		@args.empty? or raise "Extra args on command line"

	end

	def prepare

		config_doc =
			XML::Document.file @opts[:config]

		@config_elem =
			config_doc.root

		@timings_elem =
			@config_elem.find_first "timings"

		@critical_time =
			@timings_elem["critical"].to_f

		@warning_time =
			@timings_elem["warning"].to_f

		@timeout_time =
			@timings_elem["timeout"].to_f

		@base_url = URI.parse @config_elem["base-url"]

	end

	def perform_checks

		addresses = Resolv.getaddresses @base_url.host

		@worst = nil
		@successes = 0
		@failures = 0
		@mismatches = 0
		@error_codes = []
		@report_error = nil

		addresses.each do
			|address|

			check_address address

		end

		errors = @error_codes.size
		total = @successes + errors + @failures + @mismatches

		if total == 0
			critical "unable to resolve #{@base_url.host}"
		else
			message "#{total} hosts found"

			critical "#{@failures} uncontactable" \
				if @failures > 0

			critical "#{errors} errors (#{@error_codes.uniq.sort.join ","})" \
				if errors > 0

			critical "#{@mismatches} mismatches" \
				if @mismatches > 0

			if @worst != nil

				if @worst >= @critical_time
					critical "#{@worst}s time (critical is #{@critical_time})"
				elsif @worst >= @warning_time
					warning "#{@worst}s time (warning is #{@warning_time})"
				else
					message "#{@worst}s time"
				end

			end

			if @report_error != nil
				message "response '#{@report_error}'"
			end

		end

	end

	def check_address address

		cookies = {}

		begin

			# open http connection

			http =
				CustomHTTP.new \
					@base_url.host,
					@base_url.port

			http.override_address = address

			http.open_timeout = @timeout_time
			http.read_timeout = @timeout_time
			http.use_ssl = @base_url.scheme == "https"
			http.start

			success = true

			@config_elem.find("step").each do
				|step_elem|

				success =
					check_step http, cookies, step_elem

				break unless success

			end

			@successes += 1 if success

		rescue Errno::ECONNREFUSED

			@failures += 1

		rescue Timeout::Error

			@failures += 1

		end

	end

	def check_step http, cookies, step_elem

		@postscript << "performing step #{step_elem["name"]}"

		request_elem = step_elem.find_first "request"
		response_elem = step_elem.find_first "response"

		# create request

		path = @base_url.path + (request_elem["path"] || "")

		req =
			case request_elem["method"] || "get"
			when "get"
				Net::HTTP::Get.new path
			when "post"
				Net::HTTP::Post.new path
			else
				raise "error"
			end

		# set standard headers

		req["host"] = @base_url.host
		req["user-agent"] = "hq check-site"

		unless cookies.empty?
			req["cookie"] =
				cookies.map {
					|name, value|
					"#{name}=#{value}"
				}.join ", "
		end

		# set custom headers

		request_elem.find("header").each do
			|header_elem|
			req[header_elem["name"]] = header_elem["value"]
		end

		# set http auth

		if request_elem["username"]
			req.basic_auth \
				request_elem["username"],
				request_elem["password"]
		end

		# set form data

		form_data = {}

		request_elem.find("param").each do |param_elem|
			form_data[param_elem["name"]] = param_elem["value"]
		end

		req.set_form_data form_data

		# make request

		start_time = Time.now

		res = http.request req

		end_time = Time.now
		duration = end_time - start_time

		# save cookies

		if res["set-cookie"]
			WEBrick::Cookie.parse_set_cookies(res["set-cookie"]).each do
				|cookie|
				cookies[cookie.name] = cookie.value
			end
		end

		# process results

		@worst = duration if @worst == nil
		@worst = duration if duration > @worst

		debug "REQUEST #{req.path}"
		req.each { |k,v| debug "  #{k}: #{v}" }
		debug "RESPONSE #{res.code} #{res.message}"
		res.each { |k,v| debug "  #{k}: #{v}" }

		if res.code != "200"

			debug "EXPECTED response code 200"

			if @report_error == nil &&
				res.body =~ /#{response_elem["report-error"]}/

				@report_error = $1

			end

			@error_codes << res.code
			return false

		elsif response_elem["body-regex"] &&
			res.body !~ /#{response_elem["body-regex"]}/

			debug "EXPECTED body to match #{response_elem["body-regex"]}"

			if @opts[:debug]
				debug "BODY"
				debug res.body.gsub(/^/, "  ")
			end

			@mismatches += 1
			return false

		end

		return true

	end

	def debug message
		@postscript << message
	end

end
end
end
