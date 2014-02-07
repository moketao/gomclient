package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketDown;
	import com.moketao.socket.ISocketUp;

	/** 玩家 **/
	public class Player implements ISocketUp,ISocketDown{
		public var SID:String;      //String，随机字符串
		public var NickName:String; //String，用户自定义名
		public var State:int;       //8，状态，-1下线，0上线但尚未通过登录验证、或未初始化，1在线
		public var Map:String;      //String，所在地图

		/** 玩家 **/
		public function Player(){}
		public function PackInTo(b:CustomByteArray):void{
			b.writeUTF(SID);      //String（随机字符串）
			b.writeUTF(NickName); //String（用户自定义名）
			b.WriteInt8(State);   //8（状态，-1下线，0上线但尚未通过登录验证、或未初始化，1在线）
			b.writeUTF(Map);      //String（所在地图）
		}
		public function UnPackFrom(b:CustomByteArray):*{
			SID = b.readUTF();      //String（随机字符串）
			NickName = b.readUTF(); //String（用户自定义名）
			State = b.ReadInt8();   //8（状态，-1下线，0上线但尚未通过登录验证、或未初始化，1在线）
			Map = b.readUTF();      //String（所在地图）
			return this;
		}
	}
}
