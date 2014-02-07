package com.moketao.socket.save {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class ServerUp {
		public static function save(main:GomClient):void {
			//handle.go
			var filePath:String=main.pathServer.text + "\\handle.go";
			var f:File=new File(filePath);
			var s:FileStream=new FileStream();
			s.open(f, FileMode.READ);

			var isNodeClass:Boolean;
			var fileName:String="C" + main.cmd_name.text + "Up"; //文件名
			if (fileName.search(new RegExp(/\d/)) == -1) {
				fileName=main.cmd_name.text; //如果是数组内的 NodeClass 则不需要加 C前缀和 Up后缀
				isNodeClass=true;
			} else {
				//如果是C10000Up格式的，需要注册到 handle.go
				var out:String=s.readUTFBytes(s.bytesAvailable);
				s.close();
				var reg:RegExp;
				var old:String;
				var arr:Array;
				var strWillAdd:String="\tCMD.C" + main.cmd_name.text + "up = ACMD{" + main.cmd_name.text + ", f" + main.cmd_name.text + "Up}";
				if (out.search(strWillAdd) == -1) {
					reg=/\t\/\/moeditor struct start[\s\S]*moeditor struct end/m;
					arr=out.match(reg);
					old=String(arr[0]).replace("\t//moeditor struct end", "");
					old=old + "\tC" + main.cmd_name.text + "up ACMD" + "\n\t//moeditor struct end";
					out=out.replace(reg, old);

					reg=/\t\/\/moeditor init start[\s\S]*moeditor init end/m;
					arr=out.match(reg);
					old=String(arr[0]).replace("\t//moeditor init end", "");
					old=old + strWillAdd + "\n\t//moeditor init end";
					out=out.replace(reg, old);

					CmdFile.SaveClientCmd(filePath, out);
				}
			}

			out="";
			var fields:String="";
			var unpacks:String="";
			var packs:String="";
			for (var i:int=0; i < main.body.numChildren; i++) {
				var line:Line=main.body.getChildAt(i) as Line;
				var d:LineData=line.getData();
				var nodeClassName:String=getClassName(d.desc);
				fields+="	" + d.name + " " + toTypeString(d.type, nodeClassName) + " //" + d.type + "，" + d.desc + "\n";
				if (d.type != "Array") {
					unpacks+="	s." + d.name + " = " + toReadFunc(d.type) + "//" + d.desc + "\n";
				} else {
					unpacks+="	count := int(p.ReadUInt16())//数组长度（" + d.desc + "）\n";
					unpacks+="	for i := 0; i < count; i++ {\n";
					if (isClass(nodeClassName)) {
						unpacks+="		node := new(" + nodeClassName + ")\n";
						unpacks+="		s." + d.name + " = append(s." + d.name + ", node.UnPackFrom(p))\n";
					} else {
						unpacks+="		s." + d.name + " = append(s." + d.name + ", " + toReadFunc(nodeClassName) + ")\n";
					}
					unpacks+="	}\n";
				}
				if (d.type != "Array") {
					packs+="	p." + toWriteFunc(d.type) + "(s." + d.name + ")" + "//" + d.desc + "\n";
				} else {
					packs+="	count := len(s." + d.name + ")//数组长度（" + d.desc + "）\n";
					packs+="	for i := 0; i < count; i++ {\n";
					if (isClass(nodeClassName)) {
						packs+="		s." + d.name + "[i].PackInTo(p)\n";
					} else {
						packs+="		p." + toWriteFunc(nodeClassName) + "(s." + d.name + "[i])\n";
					}
					packs+="	}\n";
				}
			}
			if (isNodeClass) {
				fields=CmdFile.fixComment(fields);
				packs=CmdFile.fixComment(packs);
				unpacks=CmdFile.fixComment(unpacks);
				out+="package handle\n\n";
				out+="import (\n";
				out+='	. "base"\n';
				out+=")\n\n";
				out+="type " + fileName + " struct {\n";
				out+=fields;
				out+="}\n\n";
				out+="func (s *" + fileName + ") UnPackFrom(p *Pack) " + fileName + " {\n";
				out+=unpacks;
				out+="	return *s\n";
				out+="}\n\n";
				out+="func (s *" + fileName + ") PackInTo(p *Pack) {\n";
				out+=packs;
				out+="}\n\n";
				out+="func (s *"+fileName+")ToBytes() []byte {\n";
				out+="	pack := NewPackEmpty()\n";
				out+="	s.PackInTo(pack)\n";
				out+="	return pack.Data()\n";
				out+="}\n";
				filePath=main.pathServer.text + "\\" + fileName + ".go";
				CmdFile.SaveClientCmd(filePath, out);
			} else {
				fields=CmdFile.fixComment(fields);
				unpacks=CmdFile.fixComment(unpacks);
				out+="package handle\n\n";
				out+="import (\n";
				out+='	. "base"\n';
				out+='	"fmt"\n';
				out+=")\n\n";
				out+="type C" + main.cmd_name.text + "Up struct {\n";
				out+=fields;
				out+="}\n\n";
				out+="func f" + main.cmd_name.text + "Up(c uint16, p *Pack, u *Player) []byte {\n";
				out+="	s := new(C" + main.cmd_name.text + "Up)\n";
				out+=unpacks;
				out+="	fmt.Println(s)//需删除，否则影响性能\n";
				out+="	res := new (C" + main.cmd_name.text + "Down)\n";
				out+="	//业务逻辑：\n";
				out+="	\n";
				out+="	return res.ToBytes()\n";
				out+="}\n\n";

				filePath=main.pathServer.text + "\\" + fileName + ".go";
				CmdFile.SaveClientCmd(filePath, out);
			}

		}

		private static function getClassName(desc:String):String {
			var reg:RegExp=/\[(\w*)\]/;
			var out:Array=desc.match(reg);
			if (out && out.length >= 1) {
				return out[0].replace("[", "").replace("]", "");
			}
			return "";
		}

		public static function isClass(type:String):Boolean {
			if (type == "8" || type == "16" || type == "32" || type == "64" || type == "u8" || type == "u16" || type == "u32" || type == "u32" || type == "f32" || type == "f64" || type == "String" || type == "Array" || type == "Number") {
				return false;
			}
			return true;
		}

		public static function toTypeString(type:String, ClassInArray:String=""):String {
			switch (type) {
				case "8":  {
					return "int8";
					break;
				}
				case "16":  {
					return "int16";
					break;
				}
				case "32":  {
					return "int32";
					break;
				}
				case "64":  {
					return "int64";
					break;
				}
				case "f32":  {
					return "float32";
					break;
				}
				case "f64":  {
					return "float64";
					break;
				}
				case "String":  {
					return "string";
					break;
				}
				case "u8":  {
					return "uint8";
					break;
				}
				case "u16":  {
					return "uint16";
					break;
				}
				case "u32":  {
					return "uint32";
					break;
				}
				case "u64":  {
					return "uint64";
					break;
				}
				case "Array":  {
					ClassInArray=isClass(ClassInArray) ? ClassInArray : toTypeString(ClassInArray);
					return "[]" + ClassInArray;
					break;
				}
			}
			return null;
		}

		public static function toReadFunc(type:String):String {
			switch (type) {
				case "8":  {
					return "p.ReadInt8()";
					break;
				}
				case "16":  {
					return "p.ReadInt16()";
					break;
				}
				case "32":  {
					return "p.ReadInt32()";
					break;
				}
				case "64":  {
					return "p.ReadInt64()";
					break;
				}
				case "f32":  {
					return "p.ReadF32()";
					break;
				}
				case "f64":  {
					return "p.ReadF64()";
					break;
				}
				case "String":  {
					return "p.ReadString()";
					break;
				}
				case "u8":  {
					return "p.ReadUInt8()";
					break;
				}
				case "u16":  {
					return "p.ReadUInt16()";
					break;
				}
				case "u32":  {
					return "p.ReadUInt32()";
					break;
				}
				case "u64":  {
					return "p.ReadUInt64()";
					break;
				}
			}
			return null;
		}

		public static function toWriteFunc(type:String):String {
			switch (type) {
				case "8":  {
					return "WriteInt8";
					break;
				}
				case "16":  {
					return "WriteInt16";
					break;
				}
				case "32":  {
					return "WriteInt32";
					break;
				}
				case "64":  {
					return "WriteInt64";
					break;
				}
				case "f32":  {
					return "WriteF32";
					break;
				}
				case "f64":  {
					return "WriteF64";
					break;
				}
				case "String":  {
					return "WriteString";
					break;
				}
				case "u8":  {
					return "WriteUInt8";
					break;
				}
				case "u16":  {
					return "WriteUInt16";
					break;
				}
				case "u32":  {
					return "WriteUInt32";
					break;
				}
				case "u64":  {
					return "WriteUInt64";
					break;
				}
			}
			return null;
		}
	}
}
