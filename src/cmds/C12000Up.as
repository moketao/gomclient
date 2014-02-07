package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketUp;

	/** 申请进入某地图或FB **/
	public class C12000Up implements ISocketUp{
		public var MapName:String; //String，地图名字
		/** 申请进入某地图或FB **/
		public function C12000Up(){}
		public function PackInTo(b:CustomByteArray):void{
			b.writeUTF(MapName); //String（地图名字）
		}
	}
}
