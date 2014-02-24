require 'oj'
require 'faye'

Faye::WebSocket.load_adapter('thin')
# Faye.logger = lambda { |m| puts m }

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

# override Thin to response flashpolicy
# Thin::Connection#receive_data also override by faye-websocket
class Thin::Connection
  alias :faye_receive_data :thin_receive_data

  POLICY_FILE_REQUEST = /^<policy-file-request\/>.*/
  @@socket_policy_xml =  File.read('./flashpolicy.xml')

  def receive_data(data)
    if POLICY_FILE_REQUEST =~ data
      send_data @@socket_policy_xml
      close_connection_after_writing
    else
      faye_receive_data(data)
    end
  end
end

faye_server = Faye::RackAdapter.new(http_crossdomain, {mount: "/faye", timeout: 60 })
run faye_server
