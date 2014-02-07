package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketUp;

	/** 移动 **/
	public class C12001Up implements ISocketUp{
		public var XX:Number;  //f32，横坐标
		public var ZZ:Number;  //f32，纵坐标
		public var YY:Number;  //f32，高度
		public var Dir:Number; //f32，方向
		public var Action:int; //u16，动作（静止、走路、奔跑、跑跳、原地跳、左横移、右横移、退后、退跑、攻击1、攻击2等等）
		/** 移动 **/
		public function C12001Up(){}
		public function PackInTo(b:CustomByteArray):void{
			b.writeFloat(XX);      //f32（横坐标）
			b.writeFloat(ZZ);      //f32（纵坐标）
			b.writeFloat(YY);      //f32（高度）
			b.writeFloat(Dir);     //f32（方向）
			b.WriteUInt16(Action); //u16（动作（静止、走路、奔跑、跑跳、原地跳、左横移、右横移、退后、退跑、攻击1、攻击2等等））
		}
	}
}
