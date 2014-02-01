package save
{
	public class ClientUp
	{
		public static function save(main:GomClient):void
		{
			var out:String="";
			var fields:String="";
			var packs:String="";
			for (var i:int=0; i < main.body.numChildren; i++)
			{
				var line:Line=main.body.getChildAt(i) as Line;
				var d:LineData=line.getData();
				fields+="\n		public var " + d.name + ":" + toTypeString(d.type) + ";//" + d.desc;
				packs+="\n			" + toWriteFunc(d.type) + "(" + d.name + ");//" + d.type;
			}
			fields=main.fixComment(fields);
			packs=main.fixComment(packs);
			var fileName:String="C" + main.cmd_num.text + "Up"; //文件名
			out+="package cmd{\n";
			out+="	/** " + main.cmd_name.text + " **/\n";
			out+="	public class " + fileName + " implements ISocketOut{";
			out+=fields + "\n\n";
			out+="		/** " + main.cmd_name.text + " **/\n";
			out+="		public function " + fileName + "(){}\n"
			out+="		public function packageData(b:CustomByteArray):void{";
			out+=packs;
			out+="\n		}";
			out+="\n	}"
			out+="\n}"
			
			CmdFile.SaveClientCmd(main.pathClient.text + "\\" + fileName + ".as", out);
		}
		public static function toTypeString(type:String):String
		{
			switch (type)
			{
				case "8":
				{
					return "int";
					break;
				}
				case "16":
				{
					return "int";
					break;
				}
				case "32":
				{
					return "int";
					break;
				}
				case "64":
				{
					return "Number";
					break;
				}
				case "f64":
				{
					return "Number";
					break;
				}
				case "String":
				{
					return "String";
					break;
				}
			}
			return null;
		}
		
		public static function toWriteFunc(type:String):String
		{
			switch (type)
			{
				case "8":
				{
					return "b.writeByte";
					break;
				}
				case "16":
				{
					return "b.writeShort";
					break;
				}
				case "32":
				{
					return "b.writeInt";
					break;
				}
				case "64":
				{
					return "b.writeInt64";
					break;
				}
				case "f64":
				{
					return "b.writeFloat";
					break;
				}
				case "String":
				{
					return "b.writeUTF";
					break;
				}
			}
			return null;
		}
	}
}