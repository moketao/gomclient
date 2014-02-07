package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketUp;

	/** 用SID查询某玩家是否在线 **/
	public class C10001Up implements ISocketUp{
		public var SID:String; //String，玩家唯一标示
		/** 用SID查询某玩家是否在线 **/
		public function C10001Up(){}
		public function PackInTo(b:CustomByteArray):void{
			b.writeUTF(SID); //String（玩家唯一标示）
		}
	}
}
