package com.moketao.socket {
	import flash.utils.ByteArray;
	import flash.utils.Endian;

	public class CustomByteArray extends ByteArray {
		public function CustomByteArray() {
			super();
			this.endian=Endian.BIG_ENDIAN;
		}

		/**
		 * 读Int8
		 */
		public function ReadInt8():int {
			return int(this.readByte());
		}

		/**
		 * 读Int8
		 */
		public function ReadUInt8():int {
			return uint(this.readByte());
		}

		/**
		 * 读Int16
		 */
		public function ReadInt16():int {
			return this.readShort();
		}

		/**
		 * 读IntU16
		 */
		public function ReadUInt16():int {
			return uint(this.readShort());
		}

		/**
		 * 读Int32
		 */
		public function ReadInt32():int {
			return this.readInt();
		}

		/**
		 * 读Int32
		 */
		public function ReadUInt32():uint {
			return this.readUnsignedInt();
		}

		/**
		 * 读Int64 todo:解决读负号的问题，目前只能读正整数
		 */
		public function ReadInt64():Number {
			var number:Number=this.readUnsignedByte() * Math.pow(256, 7);
			number+=this.readUnsignedByte() * Math.pow(256, 6);
			number+=this.readUnsignedByte() * Math.pow(256, 5);
			number+=this.readUnsignedByte() * Math.pow(256, 4);
			number+=this.readUnsignedByte() * Math.pow(256, 3);
			number+=this.readUnsignedByte() * Math.pow(256, 2);
			number+=this.readUnsignedByte() * Math.pow(256, 1);
			number+=this.readUnsignedByte() * 1;
			return number;
		}

		/**
		 * 读UInt64
		 */
		public function ReadUInt64():Number {
			var number:Number=this.readUnsignedByte() * Math.pow(256, 7);
			number+=this.readUnsignedByte() * Math.pow(256, 6);
			number+=this.readUnsignedByte() * Math.pow(256, 5);
			number+=this.readUnsignedByte() * Math.pow(256, 4);
			number+=this.readUnsignedByte() * Math.pow(256, 3);
			number+=this.readUnsignedByte() * Math.pow(256, 2);
			number+=this.readUnsignedByte() * Math.pow(256, 1);
			number+=this.readUnsignedByte() * 1;
			return number;
		}

		/////////////////////////////////////////////////////////////////////////////以上读，以下写
		/**
		 * 写Int8
		 */
		public function WriteInt8(value:int):void {
			this.writeByte(value);
		}

		/**
		 * 写UInt8
		 */
		public function WriteUInt8(value:int):void {
			this.writeByte(value);
		}

		/**
		 * 写Int16
		 */
		public function WriteInt16(value:int):void {
			this.writeShort(value);
		}

		/**
		 * 写UInt16
		 */
		public function WriteUInt16(value:int):void {
			this.writeShort(value);
		}

		/**
		 *  写Int32
		 */
		public function WriteInt32(value:int):void {
			this.writeInt(value);
		}

		/**
		 *  写Int32
		 */
		public function WriteUInt32(value:uint):void {
			this.writeUnsignedInt(value);
		}

		/**
		 * 写Int64 todo:解决负号的问题，目前只能写正整数
		 */
		public function WriteInt64(value:Number):void {
			var s:String=value.toString();
			//todo:有问题，这里输出的不是int64而是uint64，需修正
			s=("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" + s).substr(-64);
			for (var i:int=0; i < 8; i++) {
				this.writeByte(parseInt(s.substr(i * 8, 8), 2));
			}
		}

		/**
		 * 写UInt64
		 */
		public function WriteUInt64(value:Number):void {
			var s:String=value.toString();
			s=("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" + s).substr(-64);
			for (var i:int=0; i < 8; i++) {
				this.writeByte(parseInt(s.substr(i * 8, 8), 2));
			}
		}

		public function traceBytes():void {
			var out:String="[ ";
			for (var i:int=0; i < this.length; i++) {
				var byte:uint=this[i] as uint;
				var s:String=byte.toString(2);
				s=("00000000" + s).substr(-8) + " ";
				out+=s;
			}
			out+="]";
			this.position=0;
			trace(out);
		}
	}
}
