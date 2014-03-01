package net.faye.mixins {
	import flash.external.ExternalInterface;
	import flash.utils.getQualifiedClassName;

	public class Logging {

		public static var enable:Boolean = true;

		public static var trace_log:Boolean   = false;
		public static var console_log:Boolean = false;


		public static const LOG_LEVEL_DEBUG:int = 0;
		public static const LOG_LEVEL_INFO:int  = 1;
		public static const LOG_LEVEL_WARN:int  = 2;
		public static const LOG_LEVEL_ERROR:int = 3;
		public static const LOG_LEVEL_FATAL:int = 4;
		public static var log_level:int = LOG_LEVEL_WARN;

		public function Logging() {
		}

		public static function debug(... args):void {
			write_log(LOG_LEVEL_DEBUG, args);
		}

		public static function info(... args):void {
			write_log(LOG_LEVEL_INFO, args);
		}

		public static function warn(... args):void {
			write_log(LOG_LEVEL_WARN, args);
		}

		public static function error(... args):void {
			write_log(LOG_LEVEL_ERROR, args);
		}

		public static function fatal(... args):void {
			write_log(LOG_LEVEL_FATAL, args);
		}

		private static function write_log(level, message_args:Array):void {
			if (!enable) {
				return;
			}

			var message:String = message_args.shift();
			var replace_msg:String;
			for (var i:int = 0; i < message_args.length; ++i) {
				replace_msg = message_args[i];
				if ("Object" == flash.utils.getQualifiedClassName(message_args[i])) {
					replace_msg = JSON.stringify(message_args[i]);
				} else {
					replace_msg = message_args[i];
				}
				message = message.replace('?', replace_msg);
			}
			if (log_level <= level) {
				if (trace_log) {
					trace(message);
				}
				if (console_log && ExternalInterface.available) {
					ExternalInterface.call("console.log", message);
				}
			}
		}
	}
}
