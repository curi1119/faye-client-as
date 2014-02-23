package net.faye.transport {
	import com.adobe.net.URI;
	import net.faye.FayeClient;
	import net.faye.Envelope;

	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;

	public class THttp extends Transport {
		public function THttp(client:FayeClient, endpoint:URI) {
			super(client, endpoint);
		}

		public override function connection_type():String {
			return "long-polling";
		}

		public static function usable(client:FayeClient, endpoint:URI, callback:Function):void {
			callback(endpoint is URI);
		}

		public static function create(client:FayeClient, endpoint:URI):THttp {
			return new THttp(client, endpoint);
		}

		public override function encode(envelopes:Vector.<Envelope>):String {
			var json:String = '';
			for (var i:int = 0; i < envelopes.length; ++i) {
				json += JSON.stringify(envelopes[i].message);
			}
			return json;
		}

		private var _request_envelopes:Vector.<Envelope>;

		public override function request(envelopes:Vector.<Envelope>):void {
			_request_envelopes = envelopes
			var content:String = encode(envelopes);

			var urlLoader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(_endpoint.toString());

			request.data = content;
			request.method = URLRequestMethod.POST;
			request.contentType = 'application/json';

			//request.requestHeaders.push(new URLRequestHeader('Cookie', ''));
			//request.requestHeaders.push(new URLRequestHeader('Host', _endpoint.authority));

			//request.requestHeaders

			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, handleIOError);
			urlLoader.addEventListener(Event.COMPLETE, function(e:Event):void {
				urlLoader.removeEventListener(Event.COMPLETE, arguments.callee);
				urlLoader.removeEventListener(IOErrorEvent.IO_ERROR, handleIOError);

				var rawData:String  = String(e.target.data);
				handle_respose(rawData);
			});
			urlLoader.load(request);
		}

		public function handle_respose(respoonse:String):void {
			var message:Array = JSON.parse(respoonse) as Array;
			receive(_request_envelopes, message);
		}

		public function handleIOError(e:Event):void {
			handle_error(_request_envelopes);
		}



	}
}
