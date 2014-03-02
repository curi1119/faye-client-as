package net.faye {
	import net.faye.mixins.Deferrable;

	public class Publication {
		private var _defer:Deferrable;

		public function Publication() {
			_defer = new Deferrable;
		}

		public function set_deferred_status(status:int, value:*=null):void {
			_defer.set_deferred_status(status, value);
		}



	}
}
