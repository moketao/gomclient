package cmds {
	import flash.utils.Dictionary;

	public class CommandMap {
		private static var _instance:CommandMap=null;
		public var _CMDDic:Dictionary;
		public var _CMDWaitDic:Dictionary;

		public function CommandMap() {
			_CMDDic=new Dictionary();
			_CMDWaitDic=new Dictionary();
			configCMD();
			configWaitCMD();
		}

		public static function getInstance():CommandMap {
			if (_instance == null) {
				_instance=new CommandMap();
			}
			return _instance;
		}

		private function configCMD():void {
			//dicStart
			_CMDDic[10000]=C10000Down;
			_CMDDic[10001]=C10001Down;
			_CMDDic[12000]=C12000Down;
			_CMDDic[12001]=C12001Down;
			//dicEnd
		}

		public static function getCmdOB(cmd:int):* {
			var a_class:Class = _instance._CMDDic[cmd];
			return new a_class();
		}

		/**
		 * 需要出现等待loading的,需要的为1，需要loading并屏蔽操作的为2，不需要不用配置，为0
		 */
		public function configWaitCMD():void {
			//_CMDWaitDic[32000]=2;
			//_CMDWaitDic[15001]=1;
		}

		public function getWaitCMDObject(cmd:int):int {
			if (_CMDWaitDic[cmd] == undefined) {
				return 0;
			}
			return _CMDWaitDic[cmd];
		}

		public function delWaitCMDObject(cmd:int):void {
			delete _CMDWaitDic[cmd];
		}

	}
}
