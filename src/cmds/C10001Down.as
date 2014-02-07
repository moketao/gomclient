package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketDown;

	/** 用SID查询某玩家是否在线 **/
	public class C10001Down implements ISocketDown{
		public var Flag:int; //8，0不在线，1在线
		/** 用SID查询某玩家是否在线 **/
		public function C10001Down(){}
		public function UnPackFrom(b:CustomByteArray):*{
			Flag = b.ReadInt8();//8（0不在线，1在线）
			return this;
		}
	}
}
