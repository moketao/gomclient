package
{
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;

	public class CmdFile
	{
		public static const num2key:Object = {
			10:"LOGIN",
			11:"CHAT",
			12:"SCENE",
			13:"ROLE",
			14:"FRIEND",
			15:"BAG",
			16:"TASK",
			18:"GUILD",
			19:"ACTIVITY",
			20:"BATTLE",
			90:"SYSTEM",
			24:"TEAM",
			21:"ARENA",
			22:"RANK",
			17:"PAL",
			25:"RIDE",
			26:"PK"
		};
		
		public static const key2num:Object = {
			"LOGIN":10,
			"CHAT":11,
			"SCENE":12,
			"ROLE":13,
			"FRIEND":14,
			"BAG":15,
			"TASK":16,
			"GUILD":18,
			"ACTIVITY":19,
			"BATTLE":20,
			"SYSTEM":90,
			"TEAM":24,
			"ARENA":21,
			"RANK":22,
			"PAL":17,
			"RIDE":25,
			"PK":26
		};
		public static function SaveClientCmd(path:String,content:String):void
		{
			var f:File = new File(path);
			var s:FileStream = new FileStream();
			s.open(f,FileMode.WRITE);
			s.writeUTFBytes(content);
			s.close();
		}
	}
}