package ui {
	import flash.text.TextField;
	import flash.text.TextFieldType;

	public class TextInputForm extends TextField {
		public function TextInputForm() {
			this.type = TextFieldType.INPUT;
			this.background = true;
			this.backgroundColor = 0xFFFFFF;
			this.width = 300;
			this.height = 15;

		}
	}
}
