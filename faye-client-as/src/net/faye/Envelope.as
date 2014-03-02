package net.faye {
	import net.faye.mixins.Deferrable;

	public class Envelope {

		private var _id:int;
		private var _message:Object;

		private var _defer:Deferrable;

		public function get defer():Deferrable {
			return _defer;
		}

		public function get message():Object {
			return _message;
		}

		public function get id():int {
			return _id;
		}

		public function Envelope(message:Object, timeout:Number) {
			_defer = new Deferrable;
			trace(JSON.stringify(message));
			_id = message['id'];
			_message = message;

			_defer.timeout(timeout, false);
		}
	}
}
