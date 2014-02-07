package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketUp;

	/** 登录 **/
	public class C10000Up implements ISocketUp{
		public var SID:String; //String，
		/** 登录 **/
		public function C10000Up(){}
		public function PackInTo(b:CustomByteArray):void{
			b.writeUTF(SID); //String（）
		}
	}
}
