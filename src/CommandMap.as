package
{
	import flash.utils.Dictionary;
	
	import cmd.SCMD10000;
	
	public class CommandMap
	{
		private static var _instance:CommandMap=null;
		public var _CMDDic:Dictionary;
		public var _CMDWaitDic:Dictionary;
		
		public function CommandMap()
		{
			_CMDDic=new Dictionary();
			_CMDWaitDic=new Dictionary();
			configCMD();
			configWaitCMD();
		}
		
		public static function getInstance():CommandMap
		{
			if (_instance == null)
			{
				_instance=new CommandMap();
			}
			return _instance;
		}
		
		private function configCMD():void
		{
			_CMDDic[10000]=SCMD10000;
		}
		
		public function getCMDObject(cmd:int):Object
		{
			if (_CMDDic[cmd] == undefined)
			{
				return null;
			}
			return new _CMDDic[cmd];
		}
		
		/**
		 * 需要出现等待loading的,需要的为1，需要loading并屏蔽操作的为2，不需要不用配置，为0
		 */
		public function configWaitCMD():void
		{
			//_CMDWaitDic[32000]=2;
			//_CMDWaitDic[15001]=1;
		}
		
		public function getWaitCMDObject(cmd:int):int
		{
			if (_CMDWaitDic[cmd] == undefined)
			{
				return 0;
			}
			return _CMDWaitDic[cmd];
		}
		
		public function delWaitCMDObject(cmd:int):void
		{
			delete _CMDWaitDic[cmd];
		}
		
	}
}