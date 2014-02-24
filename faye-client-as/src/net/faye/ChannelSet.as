package net.faye {

	public class ChannelSet {

		private var _channels:Object;

		public function ChannelSet() {
			_channels = {};
		}

		public function keys():Vector.<String> {
			var key:String;
			var keys:Vector.<String> = new Vector.<String>;
			for (var s:String in _channels) {
				keys.push(s);
			}
			return keys;
		}

		public function remove(name:String):void {
			delete _channels[name];
		}

		public function has_subscription(name:String):Boolean {
			var l_keys:Vector.<String> = keys();
			for (var i:int = 0; i < l_keys.length; ++i) {
				if (l_keys[i] == name) {
					return true;
				}
			}
			return false;
		}

		public function subscribe(name:String, callback:Function):void {
			if (callback == null) {
				return;
			}

			var channel:Channel = _channels[name];
			if (channel == null) {
				channel = new Channel(name);
				channel.callback = callback;
				_channels[name] = channel; //tmp code
			}

			// channel.bind(:message, &callback)
		}

		public function unsubscribe(name:String, callback:Function):Boolean {
			var channel:Channel = _channels[name];
			if (channel == null) {
				return false;
			}
			remove(name);

			//channel.unbind(:message, &callback)
			/*
			if channel.unused?
				remove(name)
				true
			else
				false
			end
			*/
			return true;
		}

		public function distribute_message(message:Object):void {
			var name:String = message['channel'];
			var channel:Channel = _channels[name];
			if (channel) {
				channel.callback(message);
			}
		}


	}
}
