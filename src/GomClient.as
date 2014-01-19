package
{
	import com.bit101.components.ComboBox;
	import com.bit101.components.HBox;
	import com.bit101.components.InputText;
	import com.bit101.components.Label;
	import com.bit101.components.List;
	import com.bit101.components.PushButton;
	import com.bit101.components.RadioButton;
	import com.bit101.components.Style;
	import com.bit101.components.VBox;
	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.net.SharedObject;
	
	import cmd.Cmd10000Up;
	
	import common.baseData.Int16;
	import common.baseData.Int32;
	import common.baseData.Int64;
	import common.baseData.Int8;
	
	import mycom.Alert;

	[SWF(width=1280,height=400)]
	public class GomClient extends Sprite
	{
		private var s:CustomSocket;
		private var body:VBox;

		private var cmd_num:InputText;
		private var cmd_name:InputText;

		private var CmdFileNameList:ComboBox;
		private var CmdList:List;

		private var up_down1:RadioButton;

		private var up_down2:RadioButton;

		private var pathClient:InputText;

		private var pathServer:InputText;
		
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
			new Alert(stage);
			var win:HBox = new HBox(this);
			var win_left:VBox = new VBox(win); win_left.setSize(200,stage.stageHeight-20);
			CmdFileNameList = new ComboBox(win_left);
			CmdList = new List(win_left);
			
			var html:VBox = new VBox(win);
			var setting:HBox = new HBox(html);
			
			var path_label1:Label = new Label(setting,0,0,"Client cmd's src path:");
			pathClient = new InputText(setting,0,0,"",function():void{ flash.net.SharedObject.getLocal("cmd_path").data.cmd_path1 = pathClient.text; }); pathClient.width = 300;
			
			var path_label2:Label = new Label(setting,0,0,"Server cmd's src path:");
			pathServer = new InputText(setting,0,0,"",function():void{ flash.net.SharedObject.getLocal("cmd_path").data.cmd_path2 = pathServer.text; }); pathServer.width = 300;
			
			var so:SharedObject = flash.net.SharedObject.getLocal("cmd_path");
			if(so.data.cmd_path1){
				pathClient.text = so.data.cmd_path1;
				pathServer.text = so.data.cmd_path2;
			}
			
			var head:HBox = new HBox(html);
			body = new VBox(html);
			
			var btn_add:PushButton = new PushButton(head,0,0,"Add",click_AddData);
			
			var cmd_num_label:Label = new Label(head,0,0,"cmd_num"); cmd_num_label.height = 20;
			cmd_num = new InputText(head);	cmd_num.height = 20;
			
			up_down1 = new RadioButton(head,20,5,"up",true);
			up_down2 = new RadioButton(head,0,5,"down");
			var cmd_filename_label:Label = new Label(head,10,0,"  cmd_name"); cmd_filename_label.height = 20;
			cmd_name = new InputText(head);	cmd_name.height = 20;
			
			var btn_send:PushButton = new PushButton(head,0,0,"Send",click_Send);
			var btn_connet:PushButton = new PushButton(head,0,0,"reConnet",click_Conn);
			var btn_save:PushButton = new PushButton(head,0,0,"Save",click_save);
			
		}
		
		private function start():void
		{
			//s.start("s1.app888888.qqopenapp.com",8000);
			if(s.connected)s.close();
			s.start("127.0.0.1",8000);
			trace("重新连接");
		}
		
		private function click_save(e:MouseEvent):void
		{
			if(cmd_num.text=="" && cmd_name.text=="" && body.numChildren==0){
				Alert.show("未填写完整"); return;
			}
			var out:String = "";
			var fields:String = "";
			var packs:String = "";
			var upOrDown:String = up_down1.selected? "Up":"Down";
			for (var i:int = 0; i < body.numChildren; i++)
			{
				var line:Line = body.getChildAt(i) as Line;
				var d:LineData = line.getData();
				if(!d.type || !d.name) {Alert.show("未填写完整"); return;}
				fields 	+= "\n		public var "+ d.name +":"+toTypeString(d.type)+";//"+d.desc;
				packs 	+= "\n			"+toWriteFunc(d.type)+"("+ d.name +");//"+d.type;
			}
			fields = fixComment(fields);
			packs = fixComment(packs);
			var fileName:String = "C"+cmd_num.text+upOrDown;	//文件名
			out += "package cmd{\n";
			out += "	/** "+cmd_name.text+" **/\n";
			out += "	public class "+fileName+" implements ISocketOut{";
			out += 		fields 		+"\n\n";
			out += "		/** "+cmd_name.text+" **/\n";
			out += "		public function "+fileName+"(){}\n"
			out += "		public function packageData(b:CustomByteArray):void{";
			out += 				packs;
			out += "\n		}";
			out += "\n	}"
			out += "\n}"
			
			CmdFile.SaveClientCmd(pathClient.text+"\\"+fileName+".as",out);
		}		
		
		private function fixComment(lines:String):String
		{
			var out:String = "";
			var a:Array = lines.split("\n");
			var maxNum:int = 0;
			var a1:Array = [];
			var a2:Array = [];
			for (var i:int = 0; i < a.length; i++) 
			{
				var s:String = String(a[i]);
				var commentPos:int = s.indexOf("//");
				if(commentPos!=-1){
					var tmp:String = s.slice(0,commentPos);
					a1.push(tmp);
					a2.push(s.slice(commentPos+2));
					s = tmp;
				}else{
					a1.push(s);
					a2.push("");
				}
				var len:int = s.length;
				if(len>maxNum) maxNum = s.length;
			}
			for (var k:int = 0; k < a1.length; k++) 
			{
				var aline:String = a1[k];
				var acomm:String = a2[k];
				var spaceNum:int = maxNum + 1 - aline.length;
				var space:String = "";
				for (var j:int = 0; j < spaceNum; j++) 
				{
					space += " ";
				}
				if(acomm!=""){
					out += "\n"+aline+space+"//"+acomm;
				}else if(aline!=""){
					out += "\n"+aline;
				}
			}
			return out;
		}
		
		private function toWriteFunc(type:String):String
		{
			switch(type){
				case "8":{
					return "b.writeByte";
					break;
				}
				case "16":{
					return "b.writeShort";
					break;
				}
				case "32":{
					return "b.writeInt";
					break;
				}
				case "64":{
					return "b.writeInt64";
					break;
				}
				case "f64":{
					return "b.writeFloat";
					break;
				}
				case "String":{
					return "b.writeUTF";
					break;
				}
			}
			return null;
		}
		
		private function toTypeString(type:String):String
		{
			switch(type){
				case "8":{
					return "int";
					break;
				}
				case "16":{
					return "int";
					break;
				}
				case "32":{
					return "int";
					break;
				}
				case "64":{
					return "Number";
					break;
				}
				case "f64":{
					return "Number";
					break;
				}
				case "String":{
					return "String";
					break;
				}
			}
			return null;
		}
		private function click_AddData(e:MouseEvent):void
		{
			var line:Line = new Line(body);
		}
		private function click_Send(e:MouseEvent):void
		{
			var cmd:int = parseInt(cmd_num.text);
			s.sendMessage(cmd,getLines());
		}
		
		private function getLines():Array
		{
			var out:Array = [];
			for (var i:int = 0; i < body.numChildren; i++) 
			{
				var line:Line = body.getChildAt(i) as Line;
				switch(line.getType()){
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
					case "f64":{
						out.push(parseFloat(line.val.text));
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
import com.bit101.components.Label;
import com.bit101.components.PushButton;

import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;

class Line extends HBox{
	public var dropDown:ComboBox;
	public var val:InputText;
	private var tname:InputText;
	private var desc:InputText;
	public static var TYPES:Array = ["8","16","32","64","f64","String"];
	public function Line(parent:DisplayObjectContainer = null, xpos:Number = 0, ypos:Number =  0):void{
		super(parent,xpos,ypos);
		dropDown = new ComboBox(this,0,0,"Type",TYPES);	
		
		var val_label:Label = new Label(this,0,0,"val"); val_label.height = 20;
		val = new InputText(this); val.height = 20;
		
		var tname_label:Label = new Label(this,0,0,"tname"); tname_label.height = 20;
		tname = new InputText(this); tname.height = 20;
		
		var desc_label:Label = new Label(this,0,0,"desc"); tname_label.height = 20;
		desc = new InputText(this); desc.height = 20;
		
		var del:PushButton = new PushButton(this,0,0,"Delete",click_del);
	}
	public function getData():LineData{
		var d:LineData = new LineData();
		d.type = getType();
		d.name = tname.text;
		d.desc = desc.text;
		return d;
	}
	public function getType():String{
		return Line.TYPES[dropDown.selectedIndex];
	}
	private function click_del(e:MouseEvent):void
	{
		if(parent){
			parent.removeChild(this);
		}
	}
}
class LineData{
	public var type:String;
	public var name:String;
	public var desc:String;
}