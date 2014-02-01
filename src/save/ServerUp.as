package save
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class ServerUp
	{
		public static function save(main:GomClient):void
		{
			//handle.go
			var filePath:String=main.pathServer.text + "\\handle.go";
			var f:File=new File(filePath);
			var s:FileStream=new FileStream();
			s.open(f, FileMode.READ);
			
			
			var out:String=s.readUTFBytes(s.bytesAvailable);
			s.close();
			var reg:RegExp;
			var old:String;
			var arr:Array;
			
			reg=/\t\/\/moeditor struct start[\s\S]*moeditor struct end/m;
			arr=out.match(reg);
			old=String(arr[0]).replace("\t//moeditor struct end", "");
			old=old + "\tC" + main.cmd_num.text + "up ACMD" + "\n\t//moeditor struct end";
			out=out.replace(reg, old);
			
			reg=/\t\/\/moeditor init start[\s\S]*moeditor init end/m;
			arr=out.match(reg);
			old=String(arr[0]).replace("\t//moeditor init end", "");
			old=old + "\tCMD.C" + main.cmd_num.text + "up = ACMD{" + main.cmd_num.text + ", f" + main.cmd_num.text + "Up}" + "\n\t//moeditor init end";
			out=out.replace(reg, old);
			
			CmdFile.SaveClientCmd(filePath, out);
			
			out="";
			var fields:String="";
			var packs:String="";
			for (var i:int=0; i < main.body.numChildren; i++)
			{
				var line:Line=main.body.getChildAt(i) as Line;
				var d:LineData=line.getData();
				fields+="\n	" + d.name + " "+toTypeString(d.type) + ";//" + d.desc;
				packs+="\n	d." + d.name + " = " + toReadFunc(d.type) + ";";
			}
			out+="package handle\n";
			out+="	import (\n";
			out+='	. "base"\n';
			out+='	"fmt"\n';
			out+=")\n";
			out+="type C"+main.cmd_num.text+"Up struct {";
			out+=fields;
			out+="\n}\n";
			
			out+="func f"+main.cmd_num.text+"Up(c uint16, p *Pack) interface{} {\n";
			out+="	d := new(C"+main.cmd_num.text+"Up)";
			out+=packs;
			out+="\n	fmt.Println(d)//需删除，否则影响性能";
			out+="\n	return nil//需修改，返回 []byte 类型的数据，否则客户端无法收到返回数据";
			out+="\n}\n";

			filePath=main.pathServer.text + "\\C"+main.cmd_num.text+"Up.go";
			CmdFile.SaveClientCmd(filePath, out);
		}
		public static function toTypeString(type:String):String
		{
			switch (type)
			{
				case "8":
				{
					return "int8";
					break;
				}
				case "16":
				{
					return "int16";
					break;
				}
				case "32":
				{
					return "int32";
					break;
				}
				case "64":
				{
					return "int64";
					break;
				}
				case "f64":
				{
					return "float64";
					break;
				}
				case "String":
				{
					return "string";
					break;
				}
			}
			return null;
		}
		
		public static function toReadFunc(type:String):String
		{
			switch (type)
			{
				case "8":
				{
					return "p.ReadInt8()";
					break;
				}
				case "16":
				{
					return "p.ReadInt16()";
					break;
				}
				case "32":
				{
					return "p.ReadInt32()";
					break;
				}
				case "64":
				{
					return "p.ReadInt64()";
					break;
				}
				case "f64":
				{
					return "p.ReadF64()";
					break;
				}
				case "String":
				{
					return "p.ReadString()";
					break;
				}
			}
			return null;
		}
	}
}