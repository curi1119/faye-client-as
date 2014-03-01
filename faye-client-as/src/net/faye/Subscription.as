package net.faye {
	import net.faye.mixins.Deferrable;

	public class Subscription {

		private var _client:FayeClient;
		private var _channel:String;
		private var _callback:Function;
		private var _cancelled:Boolean;

		private var _defer:Deferrable;

		public function Subscription(client:FayeClient, channel:String, callback:Function) {
			_client = client;
			_channel = channel;
			_callback = callback;
			_cancelled = false;
			_defer = new Deferrable;
		}

		public function cancel():void {
			if (_cancelled) {
				_client.unsubscribe(_channel, _callback);
			}
			_cancelled = true;
		}

		public function unsubscribe():void {
			cancel();
		}

		public function set_deferred_status(status:int, value:*=null):void {
			_defer.set_deferred_status(status, value);
		}
	}
}
