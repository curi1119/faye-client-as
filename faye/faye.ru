require 'oj'
require 'faye'
require 'pry'
Faye::WebSocket.load_adapter('thin')
Faye.logger = lambda { |m| puts m }

crossdomain_xml =  File.read('./crossdomain.xml')
app = proc do |env|
  [
    200,
    {},
    [crossdomain_xml]
  ]
end
faye_server = Faye::RackAdapter.new(app, {mount: "/faye", timeout: 60 })
run faye_server
