package common.baseData {

	public class BaseInt {
		public var value:int;
		public var size:int;

		public function BaseInt(value:int=-1) {
			super();
			this.value=value;
		}

		public function toString():String {
			return value.toString();
		}


	}
}
