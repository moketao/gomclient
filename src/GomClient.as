package {
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
	import cmds.*;
	import cmds.C10000Up;
	import cmds.C12000Down;
	import cmds.C12000Up;
	import cmds.CommandMap;
	
	import common.baseData.F32;
	import common.baseData.F64;
	import common.baseData.Int16;
	import common.baseData.Int32;
	import common.baseData.Int64;
	import common.baseData.Int8;
	import common.baseData.IntU16;
	import common.baseData.IntU32;
	import common.baseData.IntU64;
	import common.baseData.IntU8;
	
	import mycom.Alert;
	
	import com.moketao.socket.save.ClientDown;
	import com.moketao.socket.save.ClientUp;
	import com.moketao.socket.save.ServerDown;
	import com.moketao.socket.save.ServerUp;
	import com.moketao.socket.CustomSocket;
	import com.moketao.socket.save.Line;
	import com.moketao.socket.save.LineData;

	[SWF(width=1280, height=400)]
	public class GomClient extends Sprite {

		public function GomClient() {
			//net
			s=CustomSocket.getInstance();

			//ui
			com.bit101.components.Style.embedFonts=false;
			com.bit101.components.Style.fontName="Consolas";
			com.bit101.components.Style.fontSize=12;

			this.addEventListener(Event.ADDED_TO_STAGE, init);
		}

		public var CmdFileNameList:ComboBox;
		public var CmdList:List;
		public var body:VBox;
		public var cmd_desc:InputText;

		public var cmd_name:InputText;

		public var pathClient:InputText;

		public var pathServer:InputText;
		public var s:CustomSocket;

		public var up_down1:RadioButton;

		public var up_down2:RadioButton;

		public function click_AddData(e:MouseEvent):void {
			var line:Line=new Line(body);
		}

		public function click_Conn(e:MouseEvent):void {
			start();
		}

		public function click_Send(e:MouseEvent):void {
			//登录
			var c1:C10000Up = new C10000Up();
				c1.SID = "mkt";
				s.sendMessage(10000,c1);
				
			
			//进入地图A
			s.addCmdListener(12000,on12000);
			var c2:C12000Up = new C12000Up();
				c2.MapName = "MapA";
			s.sendMessage(12000, c2);
			
			//移动
			s.addCmdListener(12001,on12001);
			var c3:C12001Up = new C12001Up();
				c3.XX = 1;
				c3.ZZ = 2;
				c3.YY = 3;
			s.sendMessage(12001, c3);
		}
		private function on12000(vo:C12000Down):void{
			if(vo.Flag==1)trace("进入地图");
		}
		private function on12001(vo:C12001Down):void{
			trace(vo.XX);
			trace(vo.ZZ);
			trace(vo.YY);
		}		
		public function click_save(e:MouseEvent):void {
			if (cmd_name.text == "" || cmd_desc.text == "" || body.numChildren == 0) {
				Alert.show("未填写完整");
				return;
			}
			for (var i:int=0; i < body.numChildren; i++) {
				var d:LineData=(body.getChildAt(i) as Line).getData();
				if (!d.type || !d.name) {
					Alert.show("未填写完整");
					return;
				}
				if (d.type == "Array") {
					if (d.desc.indexOf("[") == -1) {
						Alert.show("未指定数组内部的数据类型，请在desc中用类似 [NodeClassName] 的格式来指定", 17);
						return;
					}
				}
			}
			var upOrDown:String=up_down1.selected ? "Up" : "Down";
			if (upOrDown == "Up") {
				ClientUp.save(this);
				ServerUp.save(this);
			} else {
				ClientDown.save(this);
				ServerDown.save(this);
			}
			Alert.show("保存完成");
		}

		public function getLines():Array {
			var out:Array=[];
			for (var i:int=0; i < body.numChildren; i++) {
				var line:Line=body.getChildAt(i) as Line;
				switch (line.getType()) {
					case "8":  {
						out.push(new Int8(parseInt(line.val.text)));
						break;
					}
					case "16":  {
						out.push(new Int16(parseInt(line.val.text)));
						break;
					}
					case "32":  {
						out.push(new Int32(parseInt(line.val.text)));
						break;
					}
					case "64":  {
						out.push(new Int64(parseFloat(line.val.text)));
						break;
					}
					case "f32":  {
						out.push(new F32(parseFloat(line.val.text)));
						break;
					}
					case "f64":  {
						out.push(new F64(parseFloat(line.val.text)));
						break;
					}
					case "String":  {
						out.push(line.val.text);
						break;
					}
					case "u8":  {
						out.push(new IntU8(parseFloat(line.val.text)));
						break;
					}
					case "u16":  {
						out.push(new IntU16(parseFloat(line.val.text)));
						break;
					}
					case "u32":  {
						out.push(new IntU32(parseFloat(line.val.text)));
						break;
					}
					case "u64":  {
						out.push(new IntU64(parseFloat(line.val.text)));
						break;
					}
					default:
						throw new Error("不可识别类型");
				}
			}

			return out;
		}

		public function init(e:Event):void {
			//net
			start();

			//ui
			new Alert(stage);
			new CommandMap();
			var win:HBox=new HBox(this);
			var win_left:VBox=new VBox(win);
			win_left.setSize(200, stage.stageHeight - 20);
			CmdFileNameList=new ComboBox(win_left);
			CmdList=new List(win_left);

			var html:VBox=new VBox(win);
			var setting:HBox=new HBox(html);

			var path_label1:Label=new Label(setting, 0, 0, "Client cmd's src path:");
			pathClient=new InputText(setting, 0, 0, "", function():void {
				flash.net.SharedObject.getLocal("cmd_path").data.cmd_path1=pathClient.text;
			});
			pathClient.width=300;

			var path_label2:Label=new Label(setting, 0, 0, "Server cmd's src path:");
			pathServer=new InputText(setting, 0, 0, "", function():void {
				flash.net.SharedObject.getLocal("cmd_path").data.cmd_path2=pathServer.text;
			});
			pathServer.width=300;

			var so:SharedObject=flash.net.SharedObject.getLocal("cmd_path");
			if (so.data.cmd_path1) {
				pathClient.text=so.data.cmd_path1;
				pathServer.text=so.data.cmd_path2;
			}

			var head:HBox=new HBox(html);
			body=new VBox(html);

			var btn_add:PushButton=new PushButton(head, 0, 0, "Add", click_AddData);

			var cmd_name_label:Label=new Label(head, 0, 0, "cmd_num_or_node_name");
			cmd_name_label.height=20;
			cmd_name=new InputText(head);
			cmd_name.height=20;

			up_down1=new RadioButton(head, 20, 5, "up", true);
			up_down2=new RadioButton(head, 0, 5, "down");
			var cmd_filename_label:Label=new Label(head, 10, 0, "  cmd_desc");
			cmd_filename_label.height=20;
			cmd_desc=new InputText(head);
			cmd_desc.height=20;

			var btn_send:PushButton=new PushButton(head, 0, 0, "Send", click_Send);
			var btn_connet:PushButton=new PushButton(head, 0, 0, "reConnet", click_Conn);
			var btn_save:PushButton=new PushButton(head, 0, 0, "Save", click_save);
		}

		public function start():void {
			//s.start("s1.app888888.qqopenapp.com",8000);
			if (s.connected)
				s.close();
			s.start("127.0.0.1", 8000);
			trace("重新连接");
		}
	}
}


