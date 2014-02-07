package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketDown;

	/** 登录 **/
	public class C10000Down implements ISocketDown{
		public var Flag:int; //8，1登录成功，0登录失败
		/** 登录 **/
		public function C10000Down(){}
		public function UnPackFrom(b:CustomByteArray):*{
			Flag = b.ReadInt8();//8（1登录成功，0登录失败）
			return this;
		}
	}
}
