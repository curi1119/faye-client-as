package ui {
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;

	public class CoreButton extends Sprite {

		private var _callback:Object;
		private var _callbackResponse:Boolean;
		private var _textFormat:TextFormat;
		private var _textField:TextField;
		private var _arg:Object;

		/**-------------------------------------------------------------------
		 * ボタンクラス
		   -------------------------------------------------------------------*/
		public function CoreButton(a_label:String, a_callback:Object, a_arg:Object=null) {
			_callback = a_callback;
			_arg = a_arg;

			_textFormat = new TextFormat("", 15, 0x000000);
			_textFormat.align = TextFormatAlign.LEFT;
			_textField = new TextField();
			_textField.wordWrap = false;
			_textField.type = TextFieldType.DYNAMIC;
			_textField.autoSize = TextFieldAutoSize.LEFT;
			_textField.selectable = false;
			_textField.mouseEnabled = false;
			_textField.defaultTextFormat = _textFormat;
			_textField.text = a_label;
			addChild(_textField);

			drawChenge(false);

			addEventListener(MouseEvent.CLICK, onClick);
			addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
		}

		/**-------------------------------------------------------------------
		 * デストラクタ
		   -------------------------------------------------------------------*/
		public function destructer():void {
			if (hasEventListener(MouseEvent.CLICK)) {
				removeEventListener(MouseEvent.CLICK, onClick);
			}
			if (hasEventListener(MouseEvent.MOUSE_OVER)) {
				removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
			}
			if (hasEventListener(MouseEvent.MOUSE_OUT)) {
				removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
			}
		}

		/**-------------------------------------------------------------------
		 * ボタンの大きさを取得
		   -------------------------------------------------------------------*/
		public function getButtonWidth():Number {
			return _textField.width;
		}

		public function getButtonHeight():Number {
			return _textField.height;
		}

		/**-------------------------------------------------------------------
		 * 描画の変更
		   -------------------------------------------------------------------*/
		private function drawChenge(over:Boolean):void {
			graphics.clear();
			if (over) {
				graphics.beginFill(0xBBBBBB, 1);
				graphics.drawRoundRect(0, 0, _textField.width, _textField.height, 10);
				graphics.endFill();
			} else {
				graphics.beginFill(0xAAAAAA, 1);
				graphics.drawRoundRect(0, 0, _textField.width, _textField.height, 10);
				graphics.endFill();
			}
		}

		/**-------------------------------------------------------------------
		 * マウス制御
		   -------------------------------------------------------------------*/
		private function onClick(e:MouseEvent):void {
			if (_callback) {
				_callback(_arg);
			}
		}

		private function onMouseOver(e:MouseEvent):void {
			Mouse.cursor = "button";
			drawChenge(true);
		}

		private function onMouseOut(e:MouseEvent):void {
			Mouse.cursor = "auto";
			drawChenge(false);
		}
	}
}
