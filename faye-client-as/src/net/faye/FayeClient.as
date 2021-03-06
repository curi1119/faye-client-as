package net.faye {
	import com.adobe.net.URI;

	import flash.events.TimerEvent;
	import flash.utils.Timer;

	import net.faye.Faye;
	import net.faye.mixins.Deferrable;
	import net.faye.mixins.Logging;
	import net.faye.transport.Transport;

	public class FayeClient {

		public static const UNCONNECTED:int     = 1;
		public static const CONNECTING:int      = 2;
		public static const CONNECTED:int       = 3;
		public static const DISCONNECTED:int    = 4;

		public static const HANDSHAKE:String    = "handshake";
		public static const RETRY:String        = "retry";
		public static const NONE:String         = "none";

		public static const CONNECTION_TIMEOUT:Number   = 60.0;
		public static const DEFAULT_RETRY:Number        = 5.0;
		public static const MAX_REQUEST_SIZE:int        = 2048;


		private var _options:Object;
		private var _advice:Object;

		private var _client_id:String;
		private var _state:int;

		private var _message_id:int;
		private var _connect_request:Boolean = false;

		private var _disabled:Vector.<String>;

		private var _channels:ChannelSet;
		private var _transport:Transport;
		private var _transport_up:Boolean;
		private var _transports:Object;

		private var _cookies:Object;
		private var _endpoint:URI;
		private var _endpoints:Object;
		private var _headers:Object;
		private var _max_request_size:int;
		private var _retry:uint;

		private var _defer:Deferrable;


		public function get client_id():String {
			return _client_id;
		}

		public function get endpoint():URI {
			return _endpoint;
		}

		public function get headers():Object {
			return _headers;
		}

		public function get transports():Object {
			return _transports;
		}

		public function set transports(value:Object):void {
			_transports = value;
		}

		public function get timeout():Number {
			return _advice['timeout'];
		}

		public function FayeClient(a_endpoint:String, a_options:Object=null) {
			// AS specification
			_defer = new Deferrable;
			Transport.init_transports();

			Logging.info('New client created for ?', a_endpoint)

			_options = (a_options == null ? {} : a_options);
			_endpoint = new URI(a_endpoint);
			if (_options.hasOwnProperty('endpoints') && _options['endpoints']) {
				_endpoints = _options['endpoints'];
			} else {
				_endpoints = {};
			}
			_transports = {};
			_headers = {};
			_disabled = new Vector.<String>;
			if (_options.hasOwnProperty('retry') && _options['retry']) {
				_retry = _options['retry'];
			} else {
				_retry = DEFAULT_RETRY;
			}

			for (var key:String in _endpoints) {
				_endpoints[key] = new URI(_endpoints[key]);
			}

			_max_request_size = MAX_REQUEST_SIZE;

			_state = UNCONNECTED;
			_channels = new ChannelSet;
			_message_id = 0;

			var interval:Number;
			if (_options.hasOwnProperty('interval')) {
				interval = 1000.0 * _options['interval'];
			} else {
				interval = 1000.0 * Faye.Engine_INTERVAL;
			}
			var timeout:Number;
			if (_options.hasOwnProperty('timeout')) {
				timeout = 1000.0 * _options['timeout'];
			} else {
				timeout = 1000.0 * CONNECTION_TIMEOUT;
			}
			_advice = {'reconnect': RETRY, 'interval': interval, 'timeout': timeout};
		}

		public function disable(feature):void {
			_disabled.push(feature);
		}

		public function set_header(name:String, value:String):void {
			_headers[name] = value;
		}

		public function handshake(block:Function):void {
			if (_advice['reconnect'] == NONE) {
				return;
			}
			if (_state != UNCONNECTED) {
				return;
			}

			_state = CONNECTING;

			Logging.info('Initiating handshake with ?', _endpoint.toString());
			select_transport(Faye.MANDATORY_CONNECTION_TYPES);

			var connection_type:Array = [_transport.connection_type()];
			var message:Object = {'channel': Channel.HANDSHAKE, 'version': Faye.BAYEUX_VERSION, 'supportedConnectionTypes': connection_type};

			send(message, function(response:Object):void {
				if (response['successful']) {
					_state = CONNECTED;
					_client_id = response['clientId'];

					var l_supportedConnectionTypes:Array = response['supportedConnectionTypes'] as Array;
					var supportedConnTypes:Vector.<String> = new Vector.<String>;
					for (var i:int = 0; i < l_supportedConnectionTypes.length; ++i) {
						supportedConnTypes.push(l_supportedConnectionTypes[i]);
					}

					select_transport(supportedConnTypes);
					blocker(function():void {
						Logging.info('Handshake successful: ?', _client_id);

						for each (var ch:String in _channels.keys()) {
							subscribe(ch, true);
						}

						if (block != null) {
							block();
						}
					});
				} else {
					Logging.info('Handshake unsuccessful');
					_state = UNCONNECTED;
				}
			});
		}


		public function connect(block:Function=null):void {
			if (_advice['recconect'] == NONE || _state == DISCONNECTED) {
				return;
			}

			if (_state == UNCONNECTED) {
				handshake(function():void {
					connect(block);
				});
				return;
			}

			_defer.callback(block);

			if (_state != CONNECTED) {
				return;
			}
			Logging.info('Calling deferred actions for ?', _client_id);
			_defer.set_deferred_status(Deferrable.SUCCEEDED);
			_defer.set_deferred_status(Deferrable.UNKNOWN);

			if (_connect_request) {
				return;
			}
			_connect_request = true;
			Logging.info('Initiating connection for ?', _client_id)

			var messages:Object = {'channel': Channel.CONNECT, 'clientId': _client_id, 'connectionType': _transport.connection_type()};
			send(messages, function():void {
				cycle_connection();
			});
		}

		public function disconnect():void {
			if (_state != CONNECTED) {
				return;
			}
			_state = DISCONNECTED;

			var messages:Object = {'channel': Channel.DISCONNECT, 'clientId': _client_id};
			send(messages, function(response:Object):void {
				if (response['successful']) {
					_transport.close();
				}
			});
			Logging.info('Clearing channel listeners for ?', _client_id)
			_channels = new ChannelSet;
		}

		public function subscribe(channel:String, force:Boolean=false, block:Function=null):Subscription {
			var subscription:Subscription = new Subscription(this, channel, block);
			var has_subscribe:Boolean = _channels.has_subscription(channel);

			if (has_subscribe && !force) {
				_channels.subscribe(channel, block);
				subscription.set_deferred_status(Deferrable.SUCCEEDED);
				return subscription;
			}

			connect(function():void {
				if (!force) {
					_channels.subscribe(channel, block)
				}

				var message:Object = {'channel': Channel.SUBSCRIBE, 'clientId': _client_id, 'subscription': channel};

				send(message, function(response:Object):void {
					if (!response['successful']) {
						subscription.set_deferred_status(Deferrable.FAILED, response['error']);
						if (_channels.unsubscribe(channel, block)) {
							return;
						}
					}
					Logging.info('Subscription acknowledged for ? to ?', _client_id, channel)
					subscription.set_deferred_status(Deferrable.SUCCEEDED);
				});
			});
			return subscription;
		}


		public function unsubscribe(channel:String, callback:Function=null):void {
			var dead:Boolean = _channels.unsubscribe(channel, callback);
			if (!dead) {
				return;
			}
			connect(function():void {
				Logging.info('Client ? attempting to unsubscribe from ?', _client_id, channel)
				var message:Object = {'channel': Channel.UNSUBSCRIBE, 'clientId': _client_id, 'subscription': channel};
				send(message, function(response:Object):void {
					if (!response['successful']) {
						return;
					}
					Logging.info('Unsubscription acknowledged for ? from ?', _client_id, response['channel'])
				});
			});
		}

		public function publish(channel:String, data:Object):Publication {
			var publication:Publication = new Publication;
			connect(function():void {
				Logging.info('Client ? queueing published message to ?: ?', _client_id, channel, data)
				var messages:Object = {'channel': channel, 'data': data, 'clientId': _client_id};
				send(messages, function(response:Object):void {
					if (response['successful']) {
						publication.set_deferred_status(Deferrable.SUCCEEDED);
					} else {
						publication.set_deferred_status(Deferrable.FAILED, response['error']);
					}
				});
			});
			return publication;
		}

		public function receive_message(message:Object):void {
			var id:int = message['id'];

			var callback:Function;
			if (message.hasOwnProperty('successful') && message['successful']) {
				callback = _response_callbacks[id];
				delete _response_callbacks[id];
			}
			if (message['advice']) {
				handle_advice(message['advice'])
			}
			deliver_message(message);
			if (callback) {
				callback(message);
			}
			_transport_up = true;
			//trigger('transport:up');
		}

		public function message_error(messages:Array, immedidate:Boolean=false):void {
			var id:int;
			for (var i:int = 0; i < messages.length; ++i) {
				id = messages[i]['id'];

				if (immedidate) {
					transport_send(messages[i]);
				} else {
					Faye.addOneShotTimer(_retry, function():void {
						transport_send(messages[i]);
					});
				}
			}
			if (immedidate || _transport_up == false) {
				return;
			}
			_transport_up == false;
			//trigger('transport:down');
		}

		private var _blocker:Boolean;

		private function blocker(after:Function, interval_msec:uint=50):void {
			_blocker = true;
			var timer:Timer = new Timer(interval_msec, 0);
			timer.addEventListener(TimerEvent.TIMER, function():void {
				if (!_blocker) {
					timer.stop();
					timer.removeEventListener(TimerEvent.TIMER, arguments.callee);
					timer = null;
					after();
				}
			});
			timer.start();
		}

		private function select_transport(transport_types:Vector.<String>):void {
			Transport.get(this, transport_types, new Vector.<String>, function(transport:Transport):void {
				Logging.debug('Selected ? transport for ?', transport.connection_type(), transport.endpoint.toString());

				if (transport == _transport) {
					return;
				}
				if (transport) {
					transport.close();
				}
				_transport = transport;
				_blocker = false;
			});
		}

		private var _response_callbacks:Object = {};

		private function send(message:Object, callback):void {
			if (_transport == null) {
				return;
			}
			message['id'] = generate_message_id();

			if (callback != null) {
				_response_callbacks[message['id']] = callback;
			}
			transport_send(message);
		}

		private function transport_send(message:Object):void {
			if (_transport == null) {
				return;
			}

			var timeout:Number;
			if (_advice['timeout'] == null || _advice['timeout'] == 0) {
				timeout = 1.2 * _retry;
			} else {
				timeout = 1.2 * _advice['timeout'] / 1000.0;
			}

			var envelope:Envelope = new Envelope(message, timeout);

			envelope.defer.errback(function(immedidate):void {
				message_error([message], immedidate);
			});
			_transport.send(envelope);
		}

		private function generate_message_id():String {
			_message_id += 1;
			if (_message_id >= (2 ^ 32)) {
				_message_id = 0;
			}
			return _message_id.toString(36);
		}

		private function handle_advice(advice):void {
			for (var key:String in advice) {
				if (_advice[key] != advice[key]) {
					_advice[key] = advice[key];
				}
			}

			if (_advice['reconnect'] == HANDSHAKE && _state != DISCONNECTED) {
				_state = UNCONNECTED
				_client_id = null;
				cycle_connection();
			}
		}

		private function deliver_message(message:Object):void {
			if (!message.hasOwnProperty('channel') || !message.hasOwnProperty('data')) {
				return;
			}
			Logging.info('Client ? calling listeners for ? with ?', _client_id, message['channel'], message['data'])
			_channels.distribute_message(message)
		}

		private function cycle_connection():void {
			if (_connect_request) {
				_connect_request = false;
				Logging.info('Closed connection for ?', _client_id)
			}
			Faye.addOneShotTimer(_advice['interval'] / 1000.0, connect);
		}

	}
}
