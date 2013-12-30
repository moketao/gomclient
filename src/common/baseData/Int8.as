package common.baseData
{
	import game.socket.CustomByteArray;

	public class Int8 extends BaseInt
	{
		public function Int8(value:int=-1)
		{
			super(value);
			this.size=8;
		}
		
		public function setValue(dataBytes:CustomByteArray):void
		{
			value = dataBytes.readByte();
		}
	}
}