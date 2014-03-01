package net.faye.mixins {
	import com.codecatalyst.promise.Deferred;
	import com.codecatalyst.promise.Promise;

	public class Deferrable {

		private var _defer:Deferred;

		public function Deferrable() {
			_defer = new Deferred;
		}

		public function callback(a_callback:Function):void {
			_defer.promise.then(function(value:*):void {
				a_callback(value);
			});
		}

		public function errback(a_callback:Function):void {
			_defer.promise.then(null, function(value:*):void {
				a_callback(value);
			});
		}

		public function timeout(seconds:uint, message:String):void {
			Promise.timeout(null, seconds * 1000);
		}

		public function set_deferred_status(status:String, value:*=null):void {
			if (status == 'succeeded') {
				_defer.resolve(value);
			} else if (status == 'failed') {
				_defer.reject(value);
			} else {
				_defer = new Deferred;
			}
		}
	}
}
