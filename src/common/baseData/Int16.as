package common.baseData {
	import com.moketao.socket.CustomByteArray;

	public class Int16 extends BaseInt {
		public function Int16(value:int=-1) {
			super(value);
			this.size=16;
		}

		public function setValue(dataBytes:CustomByteArray):void {
			value=dataBytes.readShort();
		}
	}
}
