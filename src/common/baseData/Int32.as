package common.baseData
{
	import game.socket.CustomByteArray;

	public class Int32 extends BaseInt
	{
		public function Int32(value:int=-1)
		{
			super(value);
			this.size=32;
		}
		
		
		public function setValue(dataBytes:CustomByteArray):void
		{
			value = dataBytes.readInt();
		}
	}
}