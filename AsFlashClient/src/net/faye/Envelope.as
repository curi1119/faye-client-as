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
			_defer = new Deferrable;
			return _message;
		}

		public function get id():int {
			return _id;
		}

		public function Envelope(message:Object, timeout:uint=0) {
			_id = message['id'];
			_message = message;
			//self.timeout(timeout, false) if timeout
		}

	}
}
