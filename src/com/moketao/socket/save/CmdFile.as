package com.moketao.socket.save {
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class CmdFile {
		public static const num2key:Object={10: "LOGIN", 11: "CHAT", 12: "SCENE", 13: "ROLE", 14: "FRIEND", 15: "BAG", 16: "TASK", 18: "GUILD", 19: "ACTIVITY", 20: "BATTLE", 90: "SYSTEM", 24: "TEAM", 21: "ARENA", 22: "RANK", 17: "PAL", 25: "RIDE", 26: "PK"};

		public static const key2num:Object={
			"LOGIN": 10,
			"CHAT": 11,
			"SCENE": 12,
			"ROLE": 13,
			"FRIEND": 14,
			"BAG": 15,
			"TASK": 16,
			"GUILD": 18,
			"ACTIVITY": 19,
			"BATTLE": 20,
			"SYSTEM": 90,
			"TEAM": 24,
			"ARENA": 21,
			"RANK": 22,
			"PAL": 17,
			"RIDE": 25,
			"PK": 26};

		public static function SaveClientCmd(path:String, content:String):void {
			if(false){
				trace("======================================================================");
				trace(path+":");
				trace(content);return;
			}
			var f:File=new File(path);
			var s:FileStream=new FileStream();
			s.open(f, FileMode.WRITE);
			s.writeUTFBytes(content);
			s.close();
		}

		/**
		 * 对齐注释（不要包含\t，否则效果不佳）
		 */
		public static function fixComment(lines:String):String {
			var out:String="";
			var a:Array=lines.split("\n");
			var maxNum:int=0;
			var a1:Array=[];
			var a2:Array=[];
			for (var i:int=0; i < a.length; i++) {
				var s:String=String(a[i]);
				var commentPos:int=s.indexOf("//");
				if (commentPos != -1) {
					var tmp:String=s.slice(0, commentPos);
					a1.push(tmp);
					a2.push(s.slice(commentPos + 2));
					s=tmp;
				} else {
					a1.push(s);
					a2.push("");
				}
				var len:int=s.length;
				if (len > maxNum)
					maxNum=s.length;
			}
			for (var k:int=0; k < a1.length; k++) {
				var aline:String=a1[k];
				var acomm:String=a2[k];
				var spaceNum:int=maxNum + 1 - aline.length;
				var space:String="";
				for (var j:int=0; j < spaceNum; j++) {
					space+=" ";
				}
				if (acomm != "") {
					out+=aline + space + "//" + acomm + "\n";
				} else if (aline != "") {
					out+=aline + "\n";
				}
			}
			return out;
		}
	}
}
