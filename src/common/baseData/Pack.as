package common.baseData
{
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;

	public class Pack
	{
		public static function packageData(cmd:uint, object:Object):CustomByteArray
		{
			if (object is ISocketOut)
			{
				return object.packageData();
			}
			var byteArray:CustomByteArray=new CustomByteArray();
			//byteArray.endian = Endian.LITTLE_ENDIAN;
			var objectXml:XML=describeType(object);
			var typeName:String=objectXml.@name;
			if (typeName == "uint")
			{
				byteArray.writeShort(uint(object));
				return byteArray;
			}
			else if (typeName == "int")
			{
				byteArray.writeInt(int(object));
				return byteArray;
			}
			else if (typeName == "String")
			{
				byteArray.writeUTF(String(object));
				return byteArray;
			}
			else if (typeName == "common.baseData::Int32")
			{
				byteArray.writeInt(object.value);
				return byteArray;
			}
			else if (typeName == "common.baseData::Int16")
			{
				byteArray.writeShort(object.value);
				return byteArray;
			}
			else if (typeName == "common.baseData::Int8")
			{
				byteArray.writeByte(object.value);
				return byteArray;
			}
			else if (typeName == "common.baseData::Int64")
			{
				var s:String=object.value.toString(2);
				s=("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" + s).substr(-64);
				for (var iii:int=0; iii < 8; iii++)
				{
					byteArray.writeByte(parseInt(s.substr(iii * 8, 8), 2));
				}
			}
			else if (typeName == "Number")
			{
				//byteArray.writeDouble(Number(object));
				byteArray.writeFloat(Number(object));
			}
			else
			{
				var variables:XMLList=objectXml.variable as XMLList;
				var tempMessagArray:Array=[];
				for each (var ms:XML in variables)
				{
					tempMessagArray.push({name: ms.@name, type: ms.@type});
				}
				
				tempMessagArray=tempMessagArray.sortOn("name");
				for each (var obj:Object in tempMessagArray)
				{
					if (obj.type == "uint")
					{
						byteArray.writeShort(object[obj.name] as uint);
					}
					else if (obj.type == "int")
					{
						byteArray.writeInt(object[obj.name] as int);
						
					}
					else if (obj.type == "Number")
					{
						var num:Number=object[obj.name] as Number;
						if (isNaN(num))
						{
							num=0;
						}
						byteArray.writeDouble(num);
					}
					else if (obj.type == "String")
					{
						var str:String=object[obj.name];
						if (str == null)
						{
							str=" ";
						}
						byteArray.writeUTF(str);
					}
					else if (obj.type == "common.baseData::Int64")
					{
						var s3:String=object[obj.name].value.toString(2);
						s3=("000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000" + s3).substr(-64);
						for (var ii:int=0; ii < 8; ii++)
						{
							byteArray.writeByte(parseInt(s3.substr(ii * 8, 8), 2)); //parseInt(s3.substr(ii*8,8),2)
						}
					}
					else if (obj.type == "common.baseData::Int32")
					{
						byteArray.writeInt(object[obj.name].value);
					}
					else if (obj.type == "common.baseData::Int16")
					{
						byteArray.writeShort(object[obj.name].value);
					}
					else if (obj.type == "common.baseData::Int8")
					{
						byteArray.writeByte(object[obj.name].value);
					}
					else
					{
						var tempObj:Object=object[obj.name];
						if (tempObj is Array)
						{
							byteArray.writeShort((tempObj as Array).length);
							for each (var innerObj:Object in tempObj)
							{
								var tempByte:CustomByteArray=packageData(0, innerObj);
								byteArray.writeBytes(tempByte, 0, tempByte.length);
							}
						}
						else
						{
							//					处理依赖关系  即对象中装有其他对象
							tempByte=packageData(0, tempObj);
							byteArray.writeBytes(tempByte, 0, tempByte.length);
						}
						tempObj=null;
						innerObj=null;
						tempByte=null;
					}
				}
			}
			object=null;
			return byteArray;
		}
		/**
		 * 将二进制数据映射到对象
		 */
		public static function mappingObject(valueObject:Object, dataBytes:CustomByteArray):Object
		{
			
			if (valueObject is ISocketIn)
			{
				return valueObject.mappingObject(dataBytes);
			}
			var objectXml:XML=describeType(valueObject);
			var variables:XMLList=objectXml.variable as XMLList;
			var tempMessagArray:Array=[];
			for each (var ms:XML in variables)
			{
				tempMessagArray.push({name: String(ms.@name), type: String(ms.@type)});
			}
			tempMessagArray=tempMessagArray.sortOn("name");
			
			var bitArray:BitArray;
			for each (var obt:Object in tempMessagArray)
			{
				if (dataBytes.bytesAvailable <= 0)
				{ //如果数据包没有了  将停止解析
					break;
				}
				if (!(obt.type == "common.baseData::Int4" || obt.type == "common.baseData::Int2" || obt.type == "common.baseData::Int1"))
				{
					bitArray=null;
				}
				if (obt.type == "uint")
				{
					valueObject[obt.name]=dataBytes.readShort();
				}
				else if (obt.type == "int")
				{
					valueObject[obt.name]=dataBytes.readInt();
					
				}
				else if (obt.type == "Number")
				{
					valueObject[obt.name]=dataBytes.readFloat();
					
				}
				else if (obt.type == "String")
				{
					try
					{
						valueObject[obt.name]=dataBytes.readUTF();
					}
					catch (e:Error)
					{
						throw new Error(e.message);
					}
				}
				else if (obt.type == "common.baseData::Int64")
				{
					var number:Number=dataBytes.readUnsignedByte() * Math.pow(256, 7);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 6);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 5);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 4);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 3);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 2);
					number+=dataBytes.readUnsignedByte() * Math.pow(256, 1);
					number+=dataBytes.readUnsignedByte() * 1;
					valueObject[obt.name]=new Int64(number);
				}
				else if (obt.type == "common.baseData::Int32")
				{
					valueObject[obt.name]=new Int32(dataBytes.readInt());
				}
				else if (obt.type == "common.baseData::Int16")
				{
					valueObject[obt.name]=new Int16(dataBytes.readShort());
				}
				else if (obt.type == "common.baseData::Int8")
				{
					valueObject[obt.name]=new Int8(dataBytes.readByte());
				}
				else if (obt.type == "common.baseData::Int4")
				{
					if (bitArray == null || bitArray.position + 4 > 8)
					{
						bitArray=new BitArray(dataBytes.readUnsignedByte());
					}
					valueObject[obt.name]=new Int4(bitArray.getBits(4));
				}
				else if (obt.type == "common.baseData::Int2")
				{
					if (bitArray == null || bitArray.position + 2 > 8)
					{
						bitArray=new BitArray(dataBytes.readUnsignedByte());
					}
					valueObject[obt.name]=new Int2(bitArray.getBits(2));
				}
				else if (obt.type == "common.baseData::Int1")
				{
					if (bitArray == null || bitArray.position + 1 > 8)
					{
						bitArray=new BitArray(dataBytes.readUnsignedByte());
					}
					valueObject[obt.name]=new Int1(bitArray.getBits(1));
				}
				else
				{
					//					处理服务端单个属性是list的情况.
					var circleTimes:uint=dataBytes.readShort();
					//log.gjDebug("轮询次数" +circleTimes);
					var objs:Array=valueObject[obt.name];
					objectXml=describeType(objs.pop());
					for (var i:int=0; i < circleTimes; i++)
					{
						var VO:Class=getDefinitionByName(objectXml.@name) as Class;
						var vo:Object=new VO();
						//只支持32位整数和字符串还有其他类型，请注意
						if (objectXml.@name == "int")
						{
							objs.push(dataBytes.readInt());
						}
						else if (objectXml.@name == "String")
						{
							objs.push(dataBytes.readUTF());
						}
						else
						{
							objs.push(mappingObject(vo, dataBytes));
						}
						VO=null;
						vo=null;
					}
					
				}
			}
			objectXml=null;
			variables=null;
			tempMessagArray=null;
			ms=null;
			obt=null;
			VO=null;
			objs=null;
			
			return valueObject;
		}

	}
}