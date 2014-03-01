package net.faye.transport {
	import com.adobe.net.URI;

	import net.faye.Envelope;
	import net.faye.Faye;
	import net.faye.FayeClient;
	import net.faye.mixins.Logging;

	public class Transport {


		protected var _endpoint:URI;
		protected var _client:FayeClient;
		protected var _outbox:Vector.<Envelope>;

		private var _connection_message:Object = null;

		public function Transport(client:FayeClient, endpoint:URI) {
			_client = client;
			_endpoint = endpoint;
			_outbox = new Vector.<Envelope>;
		}

		public function get endpoint():URI {
			return _endpoint;
		}

		public function connection_type():String {
			return "";
		}

		public function batching():Boolean {
			return true;
		}

		public function close():void {

		}

		public function encode(envelopes:Vector.<Envelope>):String {
			return "";
		}

		public function send(envelope:Envelope):void {
			_outbox.push(envelope);
			//flush_large_batch();
			flush();
		}

		public function request(envelopes:Vector.<Envelope>):void {
		}

		public function flush():void {
			if (_outbox.length > 1 && _connection_message != null) {
				_connection_message['advice'] = {'timeout': 0};
			}
			request(_outbox);

			_connection_message = null;
			_outbox.length = 0;
		}

		public function flush_large_batch():void {

		}

		public function receive(envelopes:Vector.<Envelope>, responses:Array):void {
			var i:int;
			for (i = 0; i < envelopes.length; ++i) {
				envelopes[i].defer.set_deferred_status('succeeded');
			}

			responses = [].concat(responses);

			Logging.debug('Client ? received from ?: ?', _client.client_id, _endpoint.toString(), responses);

			for (i = 0; i < responses.length; ++i) {
				_client.receive_message(responses[i]);
			}
		}

		public function handle_error(envelopes:Vector.<Envelope>, immedidate:Boolean=false):void {
			for (var i:int = 0; i < envelopes.length; ++i) {
				envelopes[i].defer.set_deferred_status('failed', immedidate);
			}
		}

		protected function get_cookies():Object {
			return {};

		}

		protected function store_cookies():void {

		}

		private static var _transports:Array = new Array;

		public static function init_transports():void {
			_transports.push(new Array("websocket", TWebSocket));
			_transports.push(new Array("long-polling", THttp));
		}

		public static function get(client:FayeClient, allowed:Vector.<String>, disabled:Vector.<String>, callback:Function):void {
			var endpoint:URI = client.endpoint;
			Faye.async_each(_transports, function(pair:Array, resume:Function):void {
				var conn_type:String = pair[0];
				var klass:Class = pair[1];

				var conn_endpoint:URI = endpoint;

				var i:int = 0;
				var disabled_include:Boolean = false;
				for (i = 0; i < disabled.length; ++i) {
					if (disabled[i] == conn_type) {
						disabled_include = true;
					}
				}
				if (disabled_include) {
					resume();
					return;
				}

				var allowed_include:Boolean = false;
				for (i = 0; i < allowed.length; ++i) {
					if (allowed[i] == conn_type) {
						allowed_include = true;
						break;
					}
				}
				if (!allowed_include) {
					klass.usable(client, conn_endpoint, function():void {
					});
					resume();
					return;
				}

				klass.usable(client, conn_endpoint, function(is_usable:Boolean):void {
					if (!is_usable) {
						resume();
						return;
					}
					var transport:Transport = klass.create(client, conn_endpoint);
					callback(transport);
				});

			}, function():void {
				throw new Error('Could not find a usable connection type for ', endpoint.toString());
			});
		}
	}
}
