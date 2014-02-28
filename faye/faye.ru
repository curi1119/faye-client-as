require 'oj'
require 'faye'

Faye::WebSocket.load_adapter('thin')
Faye.logger = lambda { |m| puts m }

# for faye server response /crossdomain.xml
class CrossDomainResponse
  @@crossdomain_xml =  File.read('./crossdomain.xml')

  def call(env)
    [
     200,
     {'Content-Type' => 'text/xml'},
     [@@crossdomain_xml],
    ]
  end
end
http_crossdomain = CrossDomainResponse.new

faye_server = Faye::RackAdapter.new(http_crossdomain, {mount: "/faye", timeout: 60 })
run faye_server
