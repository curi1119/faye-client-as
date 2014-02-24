package {
	import flash.display.Sprite;
	import flash.text.TextField;

	import net.faye.FayeClient;
	import net.hires.debug.Stats;

	import ui.CoreButton;
	import ui.TextInputForm;

	[SWF(frameRate = "30", width = "1280", height = "560", backgroundColor = "0xFAFAD2", backgroundAlpha = "0")]

	public class AsFayeClient extends Sprite {


		private var _stats:Stats;
		private var _connectButton:CoreButton;
		private var _disconnectButton:CoreButton;
		private var _subscribeButton:CoreButton;
		private var _unsubscribeButton:CoreButton;
		private var _publishButton:CoreButton;
		private var _clearButton:CoreButton;
		private var _messageField:TextField;


		private var _faye:FayeClient;

		public function AsFayeClient() {
			_stats = new Stats();
			_stats.x = 650;
			_stats.y = 330;
			addChild(_stats);

			_messageField = new TextField;
			_messageField.border = true;
			_messageField.background = true;
			_messageField.backgroundColor = 0xFFFFFF;
			_messageField.text = "";
			_messageField.x = 0;
			_messageField.y = 5;
			_messageField.width = 300;
			_messageField.height = 400;
			addChild(_messageField);


			var hostLabel:TextField = new TextField;
			hostLabel.text = 'Host:';
			hostLabel.x = 300;
			hostLabel.y = 20;
			addChild(hostLabel);

			var hostForm:TextInputForm = new TextInputForm;
			hostForm.text = 'http://localhost:9300/faye';
			hostForm.x = 350;
			hostForm.y = 20;
			addChild(hostForm);

			_connectButton = new CoreButton("Connect", function():void {
				_faye = new FayeClient(hostForm.text);
				_faye.connect(function():void {
					appendText('->ConnectButton : Connected');
				});
			});
			_connectButton.x = 300;
			_connectButton.y = 50;
			addChild(_connectButton);


			_disconnectButton = new CoreButton("Disconnect", function():void {
				if (!_faye) {
					appendText('->DisconnectButton : faye is not initialized!');
				} else {
					_faye.disconnect();
					appendText('->DisconnectButton : Disconnected.');
				}
			});
			_disconnectButton.x = 300;
			_disconnectButton.y = 100;
			addChild(_disconnectButton);



			var chLabel:TextField = new TextField;
			chLabel.text = 'Channel:';
			chLabel.x = 400;
			chLabel.y = 150;
			addChild(chLabel);
			var chForm:TextInputForm = new TextInputForm;
			chForm.text = '/test';
			chForm.x = 450;
			chForm.y = 150;
			addChild(chForm);

			var logCounter:int = 0;
			_subscribeButton = new CoreButton("Subscribe", function():void {
				if (!_faye) {
					_faye = new FayeClient(hostForm.text);
				}
				_faye.subscribe(chForm.text, false, function(message:Object):void {
					var log:String = "recived msg from " + chForm.text + " : " + JSON.stringify(message);
					appendText(log);
					logCounter += 1;
					if (logCounter > 100) {
						clearMsgField();
						logCounter = 0;
					}
				});
				appendText('->SubscribeButton Subcribed: ' + chForm.text);
			});
			_subscribeButton.x = 300;
			_subscribeButton.y = 150;
			addChild(_subscribeButton);

			var unSubChLabel:TextField = new TextField;
			unSubChLabel.text = 'Channel:';
			unSubChLabel.x = 400;
			unSubChLabel.y = 200;
			addChild(unSubChLabel);
			var unSubChForm:TextInputForm = new TextInputForm;
			unSubChForm.text = '/test';
			unSubChForm.x = 450;
			unSubChForm.y = 200;
			addChild(unSubChForm);
			_unsubscribeButton = new CoreButton("Unsubscribe", function():void {
				if (!_faye) {
					appendText('->UnsubscribeButton : faye is not initialized!');
				}
				_faye.unsubscribe(unSubChForm.text, function():void {
					appendText('->UnsubscribeButton : unsubscribed.');
				});
			});
			_unsubscribeButton.x = 300;
			_unsubscribeButton.y = 200;
			addChild(_unsubscribeButton);

			var publishChLabel:TextField = new TextField;
			publishChLabel.text = 'Channel:';
			publishChLabel.x = 400;
			publishChLabel.y = 250;
			addChild(publishChLabel);
			var publishChFrom:TextInputForm = new TextInputForm;
			publishChFrom.text = '/test';
			publishChFrom.x = 450;
			publishChFrom.y = 250;
			addChild(publishChFrom);

			var publishMessageLabel:TextField = new TextField;
			publishMessageLabel.text = '{message: ';
			publishMessageLabel.x = 390;
			publishMessageLabel.y = 280;
			addChild(publishMessageLabel);
			var publishMessageForm:TextInputForm = new TextInputForm;
			publishMessageForm.text = 'hello faye!';
			publishMessageForm.x = 450;
			publishMessageForm.y = 280;
			addChild(publishMessageForm);
			var closePublishMessageLabel:TextField = new TextField;
			closePublishMessageLabel.text = '}';
			closePublishMessageLabel.x = 750;
			closePublishMessageLabel.y = 280;
			addChild(closePublishMessageLabel);
			_publishButton = new CoreButton("Publish", function():void {
				if (!_faye) {
					_faye = new FayeClient(hostForm.text);
				}
				_faye.publish(publishChFrom.text, {message: publishMessageForm.text});
				appendText('->published: ' + "{message: " + publishMessageForm.text + "}");
			});
			_publishButton.x = 300;
			_publishButton.y = 250;
			addChild(_publishButton);


			_clearButton = new CoreButton("Clear log", function():void {
				clearMsgField();
			});
			_clearButton.x = 300;
			_clearButton.y = 350;
			addChild(_clearButton);
		}

		private function appendText(text:String, wrap:Boolean=true):void {
			_messageField.text += text;
			if (wrap) {
				_messageField.text += '\n';
			}
		}

		private function clearMsgField():void {
			_messageField.text = "";
		}
	}
}
