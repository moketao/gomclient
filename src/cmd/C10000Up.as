package cmd{
	/** 登录 **/
	public class C10000Up implements ISocketOut{
		public var name:int;        //用户名
		public var password:Number; //密码

		/** 登录 **/
		public function C10000Up(){}
		public function packageData(b:CustomByteArray):void{
			b.writeByte(name);      //8
			b.writeFloat(password); //f64
		}
	}
}

