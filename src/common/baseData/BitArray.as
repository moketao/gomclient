package common.baseData {

	public class BitArray {
		public var position:uint;
		public var byte:uint;

		public function BitArray(byte:uint) {
			position=0;
			this.byte=byte;
		}

		/**
		 * 通过位取得整数
		 * @param size 要换取位的
		 *
		 */
		public function getBits(size:uint):uint {
			if ((position + size) > 8) {
				throw new RangeError("读取位超出了范围，position+size不能大于8");
//                return;  
			}
			var f:uint=((byte << position) & 0xff) >> (8 - size);
			position+=size;
			return f;

		}

		public function setBits(value:uint, size:uint):void {
			if ((position + size) > 8) {
				throw new RangeError("读取位超出了范围，position+size不能大于8");
				return;
			}
			var f:uint=value << (8 - position - size);
			byte+=f;
			position+=size;
		}
	}
}
