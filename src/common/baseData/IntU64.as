package common.baseData
{
	/**
	 *  在装包、解包的时候用的是ByteArray的writeDouble与readDouble，
	 * 大家在使用的时候要装入正整数以实现int 64 ^_^
	 * @author 巩靖
	 */	
	public class IntU64
	{
		/**
		 * value为正整数 ，大家一定要注意
		 * @param value
		 */		
		public function IntU64(value:Number=-1)
		{
			this.value = value;
		}
		
		/**
		 * 转换接收64位整型的number变量为整形字符串，10进制 
		 * 实现原理：将number重新装入ByteArray中，低位在前，两次读无符号整型将两次读出的结果以二进制方式叠加起来，接着用19位长度去精简
		 */    
		public function toString():String
		{
			return value.toString();
		}
		public static function toByteArray(num:Number):CustomByteArray
		{
			var byteArray:CustomByteArray = new CustomByteArray();
			var s:String=num.toString(2);
			s = ("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"+s).substr(-64);
			for(var i:int=0;i<8;i++)
			{
				byteArray.writeByte( parseInt(s.substr(i*8,8),2));
			}
			return byteArray;
		}		
		public function toByteArray():CustomByteArray
		{
			var byteArray:CustomByteArray = new CustomByteArray();
			var s:String=value.toString(2);
			s = ("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"+s).substr(-64);
			for(var i:int=0;i<8;i++)
			{
				byteArray.writeByte( parseInt(s.substr(i*8,8),2));
			}
			return byteArray;
		}
		
		public function setValue(dataBytes:CustomByteArray):void
		{
			var number:Number = dataBytes.readUnsignedByte()*Math.pow(256,7);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,6);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,5);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,4);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,3);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,2);
			number+=dataBytes.readUnsignedByte()*Math.pow(256,1);
			number+=dataBytes.readUnsignedByte()*1;
			value = number;
		}
		
		public var value:Number;
		public var size:int = 64;
	}
}