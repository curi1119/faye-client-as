package net.faye {

	public class Faye {
		public function Faye() {
		}

		public static const Engine_INTERVAL:Number = 0.0;
		public static const DEFAULT_ENDPONT:String = "/bayeux";

		public static const BAYEUX_VERSION:String   = '1.0'
		public static const JSONP_CALLBACK:String   = 'jsonpcallback';

		// CONNECTION_TYPES = %w[long-polling cross-origin-long-polling callback-polling websocket eventsource in-process]
		public static const CONNECTION_TYPES:Vector.<String> = new <String>["long-polling", "cross-origin-long-polling", "callback-polling", "websocket", "eventsource", "in-process"];

		// MANDATORY_CONNECTION_TYPES = %w[long-polling callback-polling in-process]
		public static const MANDATORY_CONNECTION_TYPES:Vector.<String> = new <String>["long-polling", "callback-polling", "in-process"];

		public static function async_each(list:Array, iterator:Function, callback:Function):void {
			var n:int = list.length;
			var i:int = -1;
			var calls:int = 0;
			var looping:Boolean = false;

			var loop:Function = null;
			var resume:Function = null;

			var iterate:Function = function():void {
				calls -= 1;
				i += 1;
				if (i == n) {
					if (callback) {
						callback();
					}
				} else {
					iterator(list[i], resume);
				}
			};

			loop = function():void {
				if (looping) {
					return;
				}
				looping = true;
				while (calls > 0) {
					iterate();
				}
				looping = false;
			};

			resume = function():void {
				calls += 1;
				loop();
			};
			resume();
		}

	}
}
