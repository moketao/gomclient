package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketDown;

	/** 申请进入某地图或FB **/
	public class C12000Down implements ISocketDown{
		public var MapName:String; //String，地图名字
		public var Flag:int;       //8，1进入成功，0地图不存在
		/** 申请进入某地图或FB **/
		public function C12000Down(){}
		public function UnPackFrom(b:CustomByteArray):*{
			MapName = b.readUTF();//String（地图名字）
			Flag = b.ReadInt8();//8（1进入成功，0地图不存在）
			return this;
		}
	}
}
