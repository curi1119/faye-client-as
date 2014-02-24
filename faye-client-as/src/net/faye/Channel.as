package net.faye {

	public class Channel {

		public static const HANDSHAKE:String   = '/meta/handshake';
		public static const CONNECT:String     = '/meta/connect';
		public static const SUBSCRIBE:String   = '/meta/subscribe';
		public static const UNSUBSCRIBE:String = '/meta/unsubscribe';
		public static const DISCONNECT:String  = '/meta/disconnect';

		public static const META:String        = 'meta';
		public static const SERVICE:String     = 'service';
		public var name:String;

		public function get callback():Function {
			return _callback;
		}

		public function set callback(value:Function):void {
			_callback = value;
		}

		private var _callback:Function;

		public function Channel(a_name:String) {
			name = a_name;

		}

	}
}
