package com.moketao.socket.save {
	/*
	* 一行数据  【类型】 【数值】 【删除】
	*/
	import com.bit101.components.ComboBox;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.PushButton;
	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;

	public class Line extends HBox {
		public static var TYPES:Array=["8", "16", "32", "64", "String", "f32", "f64", "u8", "u16", "u32", "u64", "Array"];

		public function Line(parent:DisplayObjectContainer=null, xpos:Number=0, ypos:Number=0):void {
			super(parent, xpos, ypos);
			dropDown=new ComboBox(this, 0, 0, "Type", TYPES);

			var val_label:Label=new Label(this, 0, 0, "val");
			val_label.height=20;
			val=new InputText(this);
			val.height=20;

			var tname_label:Label=new Label(this, 0, 0, "tname");
			tname_label.height=20;
			tname=new InputText(this);
			tname.height=20;

			var desc_label:Label=new Label(this, 0, 0, "desc");
			tname_label.height=20;
			desc=new InputText(this);
			desc.height=20;

			var del:PushButton=new PushButton(this, 0, 0, "Delete", click_del);
		}

		public var dropDown:ComboBox;
		public var val:InputText;
		public var desc:InputText;
		public var tname:InputText;

		public function getData():LineData {
			var d:LineData=new LineData();
			d.type=getType();
			d.name=tname.text;
			d.desc=desc.text;
			return d;
		}

		public function getType():String {
			return Line.TYPES[dropDown.selectedIndex];
		}

		public function click_del(e:MouseEvent):void {
			if (parent) {
				parent.removeChild(this);
			}
		}
	}

}
