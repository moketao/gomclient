package 
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import common.baseData.Int16;
	import common.baseData.Int32;
	import common.baseData.Int64;
	import common.baseData.Int8;

	public class CustomByteArray extends ByteArray
	{
		public function CustomByteArray()
		{
			super();
			this.endian=Endian.BIG_ENDIAN;
		}
			
		/**
		 * 读Int8 
		 * @return 
		 * 
		 */		
		public function readInt8():Int8
		{
			return new Int8(this.readByte());
		}
		
		/**
		 * 读Int16 
		 * @return 
		 * 
		 */		
		public function readInt16():Int16
		{
			return new Int16(this.readShort());
		}
		
		/**
		 * 读Int32 
		 * @return 
		 * 
		 */		
		public function readInt32():Int32
		{
			return new Int32(this.readInt());
		}
		
		/**
		 * 读Int64 
		 * @return 
		 * 
		 */		
		public function readInt64():Int64
		{
			var number:Number = this.readUnsignedByte()*Math.pow(256,7);
			number+=this.readUnsignedByte()*Math.pow(256,6);
			number+=this.readUnsignedByte()*Math.pow(256,5);
			number+=this.readUnsignedByte()*Math.pow(256,4);
			number+=this.readUnsignedByte()*Math.pow(256,3);
			number+=this.readUnsignedByte()*Math.pow(256,2);
			number+=this.readUnsignedByte()*Math.pow(256,1);
			number+=this.readUnsignedByte()*1;
			return new Int64(number);
		}
		
		/**
		 * 读String 
		 * @return 
		 * 
		 */		
		public function readString():String
		{
			return this.readUTF();
		}
		
		/**
		 * 写Int8 
		 * @param value
		 * 
		 */		
		public function writeInt8(value:Int8):void
		{
			this.writeByte(value.value);
		}
		
		/**
		 * 写Int16 
		 * @param value
		 * 
		 */		
		public function writeInt16(value:Int16):void
		{
			this.writeShort(value.value);
		}
		
		/**
		 *  写Int32
		 * @param value
		 * 
		 */		
		public function writeInt32(value:Int32):void
		{
			this.writeInt(value.value);
		}
		
		/**
		 * 写Int64 
		 * @param value
		 * 
		 */		
		public function writeInt64(value:Int64):void
		{
			var s:String=value.value.toString(2);
			s = ("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000"+s).substr(-64);
			for(var i:int=0;i<8;i++)
			{
				this.writeByte( parseInt(s.substr(i*8,8),2));
			}
		}
		
		/**
		 * 写String 
		 * @param value
		 * 
		 */		
		public function writeString(value:String):void
		{
			this.writeUTF(value);
		}
		
		public function traceBytes():void{
			var out:String = "[ ";
			for (var i:int = 0; i < this.length; i++) 
			{
				var byte:uint = this[i] as uint;
				var s:String=byte.toString(2);
				s = ("00000000"+s).substr(-8)+" ";
				out += s;
			}
			out += "]";
			this.position = 0;
			trace(out);
		}
	}
}