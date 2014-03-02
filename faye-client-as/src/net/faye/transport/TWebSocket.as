package net.faye.transport {
	import com.adobe.net.URI;
	import net.faye.FayeClient;
	import net.faye.Envelope;
	import net.faye.mixins.Deferrable;
	import net.faye.mixins.Timeouts;
	import com.worlize.websocket.WebSocket;
	import com.worlize.websocket.WebSocketErrorEvent;
	import com.worlize.websocket.WebSocketEvent;


	public class TWebSocket extends Transport {

		public static const UNCONNECTED:int = 1;
		public static const CONNECTING:int  = 2;
		public static const CONNECTED:int   = 3;

		public static const PROTOCOLS:Object = {'http': 'ws', 'https': 'wss'};

		private var _defer:Deferrable;
		private var _timeouts:Timeouts;

		public function TWebSocket(client:FayeClient, endpoint:URI) {
			super(client, endpoint);
			_defer = new Deferrable;
			_timeouts = new Timeouts;
		}

		public override function connection_type():String {
			return "websocket";
		}

		public static function usable(client:FayeClient, endpoint:URI, callback:Function):void {
			var self:TWebSocket = create(client, endpoint);
			self.usable(callback);
		}

		public static function create(client:FayeClient, endpoint:URI):TWebSocket {
			var sockets:Object = client.transports.websocket = client.transports.websocket || {};
			sockets[endpoint.toString()] = sockets[endpoint.toString()] || new TWebSocket(client, endpoint);
			return sockets[endpoint.toString()];
		}

		public override function batching():Boolean {
			return false;
		}

		private var _usableCallback:Function;

		public function usable(callback:Function):void {
			_usableCallback
			_defer.callback(function():void {
				callback(true);
			});
			_defer.errback(function():void {
				callback(false);
			});
			connect();
		}


		private var _pending_envelopes:Vector.<Envelope> = new Vector.<Envelope>;

		public override function request(envelopes:Vector.<Envelope>):void {
			// copy
			var l_envelopes:Vector.<Envelope> = new Vector.<Envelope>;
			for (var i:int = 0; i < envelopes.length; ++i) {
				_pending_envelopes.push(envelopes[i]);
				l_envelopes.push(envelopes[i]);
			}

			_defer.callback(function(socket:WebSocket):void {
				if (!socket) {
					return;
				}
				var json:String;
				for (var i:int = 0; i < l_envelopes.length; ++i) {
					json = JSON.stringify(l_envelopes[i].message);
					socket.sendUTF(json);
				}
			});
			connect();
		}

		private var _state:int = -1;
		private var _socket:WebSocket;
		private var _ever_connected:Boolean;
		private var _tmp_socket:WebSocket;

		public function connect():void {
			if (_state == -1) {
				_state = UNCONNECTED;
			}
			if (_state != UNCONNECTED) {
				return
			}
			_state = CONNECTING;

			var headers:Object = _client.headers;
			headers['Cookie'] = get_cookies;

			var url:URI = new URI(_endpoint.toString());
			url.scheme = PROTOCOLS[url.scheme];

			_socket = new WebSocket(url.toString(), "*");
			_socket.addEventListener(WebSocketEvent.OPEN, handleOnOpen);
			_socket.addEventListener(WebSocketEvent.CLOSED, handleOnClose);
			_socket.addEventListener(WebSocketEvent.MESSAGE, handleOnMessage);
			_socket.addEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleOnClose);
			_socket.connect();
		}

		private function handleOnOpen(event:WebSocketEvent):void {
			_state = CONNECTED;
			_ever_connected = true;
			ping();
			_defer.set_deferred_status(Deferrable.SUCCEEDED, _socket);
		}

		private function handleOnMessage(event:WebSocketEvent):void {
			var o_messages:Object = JSON.parse(event.message.utf8Data);

			var messages:Array = [].concat(o_messages as Array);
			var envelopes:Vector.<Envelope> = new Vector.<Envelope>;

			for (var i:int = 0; i < messages.length; ++i) {
				if (messages[i].hasOwnProperty('successful') && messages[i]['successful']) {
					for (var k:int = 0; k < _pending_envelopes.length; ++k) {
						if (messages[i]['id'] == _pending_envelopes[k].id) {
							envelopes.push(_pending_envelopes[k]);
							_pending_envelopes.slice(k, 1);
							break;
						}
					}
				}
			}
			receive(envelopes, messages);
		}

		private function handleOnClose(event:WebSocketEvent):void {
			errorHandler();
		}

		private function handleOnError(event:WebSocketErrorEvent):void {
			errorHandler();
		}

		private function errorHandler():void {
			var closed:Boolean = false;
			if (closed) {
				return;
			}
			closed = true;

			var wasConnected:Boolean = (_state == CONNECTED);

			_socket.removeEventListener(WebSocketEvent.OPEN, handleOnOpen);
			_socket.removeEventListener(WebSocketEvent.CLOSED, handleOnClose);
			_socket.removeEventListener(WebSocketErrorEvent.CONNECTION_FAIL, handleOnClose);
			_socket.removeEventListener(WebSocketEvent.MESSAGE, handleOnMessage);

			_socket = null;
			_state = UNCONNECTED;
			_timeouts.remove_timeout('ping');
			_defer.set_deferred_status(Deferrable.UNKNOWN);

			if (wasConnected) {
				handle_error(_pending_envelopes, true);
			} else if (_ever_connected) {
				handle_error(_pending_envelopes);
			} else {
				_defer.set_deferred_status(Deferrable.FAILED);
			}
		}

		public override function close():void {
			_socket.close();
		}

		private function ping():void {
			if (_socket == null) {
				return;
			}
			_socket.sendUTF('[]');
			_timeouts.add_timeout('ping', _client.timeout / 2000.0, ping);
		}
	}
}
