package net.faye {
	import com.adobe.net.URI;
	import net.faye.Faye;
	import net.faye.mixins.Deferrable;
	import net.faye.transport.Transport;

	import flash.events.TimerEvent;
	import flash.utils.Timer;

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

		private var _disabled:Vector.<String>; // not using

		private var _channels:ChannelSet;
		private var _transport:Transport;
		private var _transport_up:Boolean;
		public var transports:Object;

		private var _cookies:Object;
		private var _endpoint:URI;
		private var _endpoints:String;
		private var _headers:Object;
		private var _max_request_size:int;
		private var _retry:uint;

		//private var _callback:Function;
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


		public function FayeClient(a_endpoint:String, a_options:Object=null) {
			// AS specification
			_defer = new Deferrable;
			Transport.init_transports();



			_options = (a_options == null ? {} : a_options);
			_endpoint = new URI(a_endpoint);

			transports = {'websocket': {}};
			_headers = {};
			_disabled = new Vector.<String>;
			_retry = DEFAULT_RETRY;

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

		public function get timeout():Number {
			return _advice['timeout'];
		}

		public function handshake(block:Function):void {
			if (_advice['reconnect'] == NONE) {
				return;
			}
			if (_state != UNCONNECTED) {
				return;
			}

			_state = CONNECTING;

			//info('Initiating handshake with ?', @endpoint)
			trace('Initiating handshake with ', _endpoint.toString());
			select_transport(Faye.MANDATORY_CONNECTION_TYPES);

			var connection_type:Array = [_transport.connection_type()]; //[_transport.connection_type()];
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
						// info('Handshake successful: ?', @client_id)
						trace('Handshake successful:', _client_id);

						for each (var ch:String in _channels.keys()) {
							subscribe(ch, true);
						}

						if (block != null) {
							block();
						}
					});
				} else {
					//info('Handshake unsuccessful')
					//EventMachine.add_timer(@advice['interval'] / 1000.0) { handshake(&block) }
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
			//info('Calling deferred actions for ?', @client_id)
			trace('Calling deferred actions for', _client_id);
			_defer.set_deferred_status('succeeded');
			_defer.set_deferred_status('unknown');

			if (_connect_request) {
				return;
			}
			_connect_request = true;
			//info('Initiating connection for ?', @client_id)
			trace('Initiating connection for', _client_id);

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
			// info('Clearing channel listeners for ?', @client_id)
			_channels = new ChannelSet;
		}

		public function subscribe(channel:String, force:Boolean=false, block:Function=null):Subscription {
			var subscription:Subscription = new Subscription(this, channel, block);
			var has_subscribe:Boolean = _channels.has_subscription(channel);

			if (has_subscribe && !force) {
				_channels.subscribe(channel, block);
				subscription.set_deferred_status('succeeded');
				return subscription;
			}

			connect(function():void {
				if (!force) {
					_channels.subscribe(channel, block)
				}

				var message:Object = {'channel': Channel.SUBSCRIBE, 'clientId': _client_id, 'subscription': channel};

				send(message, function(response:Object):void {
					if (!response['successful']) {
						subscription.set_deferred_status('failed', response['error']);
						if (_channels.unsubscribe(channel, block)) {
							return;
						}
					}
					//info('Subscription acknowledged for ? to ?', @client_id, channels)
					trace('Subscription acknowledged for', _client_id, 'to', channel);
					subscription.set_deferred_status('succeeded');
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
				//info('Client ? attempting to unsubscribe from ?', @client_id, channel)
				trace('Client', _client_id, 'attempting to unsubscribe from', channel);
				var message:Object = {'channel': Channel.UNSUBSCRIBE, 'clientId': _client_id, 'subscription': channel};
				send(message, function(response:Object):void {
					if (!response['successful']) {
						return;
					}
					//info('Unsubscription acknowledged for ? from ?', @client_id, channels)
					var l_channel:String = response['channel'];
					trace('Unsubscription acknowledged for', _client_id, 'from', l_channel);
				});
			});
		}

		public function publish(channel:String, data:Object):void {

			connect(function():void {
				//info('Client ? queueing published message to ?: ?', @client_id, channel, data)
				trace('Client', _client_id, 'queueing published message to', channel, ':', data);
				var messages:Object = {'channel': channel, 'data': data, 'clientId': _client_id};
				send(messages, function(response:Object):void {
				/*
				if (response.successful)
					publication.setDeferredStatus('succeeded');
				else
					publication.setDeferredStatus('failed', Faye.Error.parse(response.error));
				*/

				});
			});

		}

		public function receive_message(message:Object):void {
			trace('Client receive_message');
			var id:int = message['id'];


			var callback:Function;
			if (message.hasOwnProperty('successful') && message['successful']) {
				callback = _response_callbacks[id];
				delete _response_callbacks[id];
			}
			/*
			pipe_through_extensions(:incoming, message, nil) do |message|
				next unless message
				handle_advice(message['advice']) if message['advice']
				deliver_message(message)

				callback.call(message) if callback
			end
			*/
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

		}


		private var _blocker:Boolean;

		private function blocker(after:Function, interval_msec:uint=50):void {
			_blocker = true;
			var timer:Timer = new Timer(interval_msec, 0);
			timer.addEventListener(TimerEvent.TIMER, function():void {
				if (!_blocker) {
					trace('blokcer removed');
					timer.stop();
					timer.removeEventListener(TimerEvent.TIMER, arguments.callee);
					timer = null;
					after();
				} else {
					trace('blocking');
				}
			});
			/*
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void {
			});
			*/
			timer.start();
		}

		private function select_transport(transport_types:Vector.<String>):void {
			trace('-START--select_transport');
			Transport.get(this, transport_types, new Vector.<String>, function(transport:Transport):void {
				trace('Selected', transport.connection_type(), 'transport for', transport.endpoint.toString());
				//debug('Selected ? transport for ?', transport.connection_type, transport.endpoint)

				trace(transport);
				if (transport == _transport) {
					return;
				}
				if (transport) {
					transport.close();
				}
				trace('_transport = transport;');
				_transport = transport;
				_blocker = false;
			});
			trace('-END--select_transport');
			trace('          ');
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
			trace('*send:', JSON.stringify(message));
			transport_send(message);

		/*
		pipe_through_extensions(:outgoing, message, nil) do |message|
			next unless message
			@response_callbacks[message['id']] = callback if callback
			transport_send(message)
		end
		*/
		}

		private function transport_send(message:Object):void {
			if (_transport == null) {
				return;
			}
			var timeout:uint = 1.2 * _retry;

			var envelope:Envelope = new Envelope(message, timeout);

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
		/*
		@advice.update(advice)

		if @advice['reconnect'] == HANDSHAKE and @state != DISCONNECTED
			@state = UNCONNECTED
			@client_id = nil
			cycle_connection
		end
		*/
		}

		private function deliver_message(message:Object):void {
			if (!message.hasOwnProperty('channel') || !message.hasOwnProperty('data')) {
				return;
			}
			trace('Client', _client_id, 'calling listeners for', message['channel'], 'with', message['data']);
			//info('Client ? calling listeners for ? with ?', @client_id, message['channel'], message['data'])
			_channels.distribute_message(message)
		}

		private function cycle_connection():void {
			trace('cycle_connection');

			if (_connect_request) {
				_connect_request = false;
				//info('Closed connection for ?', @client_id)
				trace('Closed connection for ', _client_id);
			}
			var timer:Timer = new Timer(_advice['interval'] / 1000.0, 1);
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, function():void {
				trace('!fire cycle_connection ');
				timer.removeEventListener(TimerEvent.TIMER_COMPLETE, arguments.callee);
				connect();
			});
			timer.start();
		}

	}
}
