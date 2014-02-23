require 'oj'
require 'faye'
Faye::WebSocket.load_adapter('thin')
Faye.logger = lambda { |m| puts m }

faye_server = Faye::RackAdapter.new({mount: "/faye", timeout: 60 })
run faye_server
