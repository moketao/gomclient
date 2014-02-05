package cmds{
	/** 用SID查询某玩家是否在线 **/
	public class C10001Downbad implements ISocketDown{
		public var Flag:int; //8，0不在线，1在线
		/** 用SID查询某玩家是否在线 **/
		public function C10001Downbad(){}
		public function UnPackFrom(b:CustomByteArray):*{
			Flag = b.ReadInt8();//8（0不在线，1在线）
			return this;
		}
	}
}
