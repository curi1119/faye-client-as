package ui {
	import flash.text.TextField;
	import flash.text.TextFieldType;

	public class TextInputForm extends TextField {
		public function TextInputForm() {
			this.type = TextFieldType.INPUT;
			this.background = true;
			this.backgroundColor = 0xFFFFFF;
			this.border = true;
			this.width = 150;
			this.height = 15;

		}
	}
}
