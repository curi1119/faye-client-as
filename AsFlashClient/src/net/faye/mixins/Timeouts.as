package net.faye.mixins {
	import flash.events.TimerEvent;
	import flash.utils.Timer;

	public class Timeouts {


		private var _timeouts:Object;

		public function Timeouts() {
			_timeouts = {};
		}

		private var _comepleteHandler:Function;

		public function add_timeout(name:String, delay:int, block:Function):void {
			if (_timeouts.hasOwnProperty(name)) {
				return;
			}

			var timer:Timer = new Timer(delay * 1000, 1);
			_comepleteHandler = function():void {
				timer.removeEventListener(TimerEvent.TIMER_COMPLETE, _comepleteHandler);
				delete _timeouts[name];
				block();
			};
			timer.addEventListener(TimerEvent.TIMER_COMPLETE, _comepleteHandler);
			timer.start();
			_timeouts[name] = timer;
		}

		public function remove_timeout(name:String):void {
			var timer:Timer = _timeouts[name];
			if (timer == null) {
				return;
			}
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER_COMPLETE, _comepleteHandler);
			timer = null;
			delete _timeouts[name];
		}

		public function remove_all_timeouts():void {
			for (var name:String in _timeouts) {
				remove_timeout(name);
			}
			_timeouts = {};
		}

	}
}
