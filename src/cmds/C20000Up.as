package cmds {
	/** Just a Test. **/
	public class C20000Up implements ISocketUp {
		public var a1:Array=[]; //Array，包含[PosVO]
		public var a2:int; //u8，Just a val

		/** Just a Test. **/
		public function C20000Up() {
		}

		public function PackInTo(b:CustomByteArray):void {
			b.WriteUInt16(a1.length); //写入数组长度，（包含[PosVO]）
			for (var i:int=0; i < a1.length; i++) { //深层递归mapping
				(a1[i] as PosVO).PackInTo(b);
			}
			b.WriteUInt8(a2); //u8（Just a val）
		}
	}
}
