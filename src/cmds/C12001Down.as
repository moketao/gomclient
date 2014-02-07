package cmds{
	import com.moketao.socket.CustomByteArray;
	import com.moketao.socket.ISocketDown;

	/** 移动 **/
	public class C12001Down implements ISocketDown{
		public var XX:Number;  //f32，横坐标
		public var ZZ:Number;  //f32，纵坐标
		public var YY:Number;  //f32，高度
		public var Dir:Number; //f32，方向
		public var Action:int; //u16，动作（静止、走路、奔跑、跑跳、原地跳、左横移、右横移、退后、退跑、攻击1、攻击2等等）
		public var Flag:int;   //8，0不可移动，1成功移动
		/** 移动 **/
		public function C12001Down(){}
		public function UnPackFrom(b:CustomByteArray):*{
			XX = b.readFloat();//f32（横坐标）
			ZZ = b.readFloat();//f32（纵坐标）
			YY = b.readFloat();//f32（高度）
			Dir = b.readFloat();//f32（方向）
			Action = b.ReadUInt16();//u16（动作（静止、走路、奔跑、跑跳、原地跳、左横移、右横移、退后、退跑、攻击1、攻击2等等））
			Flag = b.ReadInt8();//8（0不可移动，1成功移动）
			return this;
		}
	}
}
