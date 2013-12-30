package
{
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.PushButton;
	import com.bit101.components.Style;
	import com.bit101.components.VBox;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import common.baseData.Int16;
	import common.baseData.Int32;
	import common.baseData.Int64;
	import common.baseData.Int8;

	[SWF(width=800,height=400)]
	public class GomClient extends Sprite
	{
		private var s:CustomSocket;
		private var body:VBox;

		private var input_cmd_num:InputText;
		public function GomClient()
		{
			//net
			s = CustomSocket.getInstance();
			
			//ui
			com.bit101.components.Style.embedFonts = false;
			com.bit101.components.Style.fontName = "Consolas";
			com.bit101.components.Style.fontSize = 12;
			
			this.addEventListener(Event.ADDED_TO_STAGE,init);
		}
		private function init(e:Event):void{
			//net
			start();
			
			//ui
			var html:VBox = new VBox(this);
			var head:HBox = new HBox(html);
			body = new VBox(html);
			var btn_add:PushButton = new PushButton(head,0,0,"Add",click_AddData);
			input_cmd_num = new InputText(head);	input_cmd_num.height = 20;
			var btn_send:PushButton = new PushButton(head,0,0,"Send",click_Send);
			var btn_connet:PushButton = new PushButton(head,0,0,"reConnet",click_Conn);
		}

		private function start():void
		{
			//s.start("s1.app888888.qqopenapp.com",8000);
			if(s.connected)s.close();
			s.start("127.0.0.1",8000);
			trace("重新连接");
		}
		
		private function click_AddData(e:MouseEvent):void
		{
			var line:Line = new Line(body);
		}
		private function click_Send(e:MouseEvent):void
		{
			var cmd:int = parseInt(input_cmd_num.text);
			s.sendMessage(cmd,getLines());
		}
		
		private function getLines():Array
		{
			var out:Array = [];
			for (var i:int = 0; i < body.numChildren; i++) 
			{
				var line:Line = body.getChildAt(i) as Line;
				var type:String = Line.TYPES[line.dropDown.selectedIndex];
				switch(type){
					case "8":{
						out.push(new Int8(parseInt(line.val.text)));
						break;
					}
					case "16":{
						out.push(new Int16(parseInt(line.val.text)));
						break;
					}
					case "32":{
						out.push(new Int32(parseInt(line.val.text)));
						break;
					}
					case "64":{
						out.push(new Int64(parseFloat(line.val.text)));
						break;
					}
					case "String":{
						out.push(line.val.text);
						break;
					}
				}
			}
			
			return out;
		}
		
		private function click_Conn(e:MouseEvent):void
		{
			start();
		}
	}
}

/*
 * 一行数据  【类型】 【数值】 【删除】
 */
import com.bit101.components.ComboBox;
import com.bit101.components.HBox;
import com.bit101.components.InputText;
import com.bit101.components.PushButton;

import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;

class Line extends HBox{
	public var dropDown:ComboBox;
	public var val:InputText;
	public static var TYPES:Array = ["8","16","32","64","String"];
	public function Line(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0):void{
		super(parent,xpos,ypos);
		dropDown = new ComboBox(this,0,0,"Type",TYPES);	
		val = new InputText(this); val.height = 20;
		var del:PushButton = new PushButton(this,0,0,"Delete",click_del);
	}
	
	private function click_del(e:MouseEvent):void
	{
		if(parent){
			parent.removeChild(this);
		}
	}
}