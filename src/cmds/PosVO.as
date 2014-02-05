package cmds {
	/** Just a Test. **/
	public class PosVO implements ISocketUp, ISocketDown {
		public var arr:Array=[]; //Array，包含[u8]
		public var str:String; //String，Just a str

		/** Just a Test. **/
		public function PosVO() {}
		public function PackInTo(b:CustomByteArray):void {
			b.WriteUInt16(arr.length); //写入数组长度，（包含[u8]）
			for (var i:int=0; i < arr.length; i++) { //深层递归mapping
				b.WriteUInt8(arr[i]);
			}
			b.writeUTF(str); //String（Just a str）
		}

		public function UnPackFrom(b:CustomByteArray):* {
			var len:int=b.ReadUInt16(); //读取数组长度，（包含[u8]）
			for (var i:int=0; i < len; i++) {
				arr.push(b.ReadUInt8());
			}
			str=b.readUTF(); //String（Just a str）
			return this;
		}
	}
}
