package
{
	import com.ericfeminella.collections.HashMap;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Endian;
	import flash.utils.describeType;
	import flash.utils.getDefinitionByName;
	
	import CommandMap;
	
	import common.baseData.BitArray;
	import common.baseData.Int1;
	import common.baseData.Int16;
	import common.baseData.Int2;
	import common.baseData.Int32;
	import common.baseData.Int4;
	import common.baseData.Int64;
	import common.baseData.Int8;


	//	import uisystem.view.UiSystemMediator;	

	/**自定义socket 数据通信管理器
	 *
	 * @author liudisong
	 *
	 */
	public class CustomSocket extends Socket
	{
		public static var ip:String;
		public static var port:int;
		public static const tgwStrPre:String = "tgw_l7_forward\r\nHost: ";
		public static const tgwStrEnd:String = "\r\n\r\n";
		private static var one:CustomSocket;

		/**
		 *是否已接收到策略字串
		 */
		private var _isrecvProcy:Boolean=false;

		private var _retryTime:int=0;
			private var deadIdle:Dictionary;


		/**
		 *构造函数
		 */
		public function CustomSocket()
		{
			super(null, 0);
			if (one != null){
				throw new Error("单例模式类")
			}
			_cmdMap=CommandMap.getInstance();
			_ccmdParseDic=new HashMap();
			_scmdParseDic=new HashMap();
		}
		public static function getInstance():CustomSocket
		{
			if (one == null)
			{
				one=new CustomSocket();
			}
			return one;
		}

		/**
		 *启动自定义socket
		 */
		public function start(_ip:String, _port:int):void
		{
			ip = _ip;
			port=_port;
			this.configureListeners();
			super.connect(ip, port);
		}

		/**
		 * 针对QQ平台，添加TGW负载均衡包头
		 */
		private function addTgwHead(sendBytes:CustomByteArray):void
		{
			var tgwStr:String=tgwStrPre + ip + ":" + port + tgwStrEnd;
			sendBytes.writeMultiByte(tgwStr, "GBK");
			_isFirstSend=false;
		}

		private var _isFirstSend:Boolean=true;

		/**
		 *配置socket监听事件
		 */
		private function configureListeners():void
		{
			addEventListener(Event.CLOSE, closeHandler);
			addEventListener(Event.CONNECT, connectHandler);
			addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}
		/**
		 * 收到服务端数据会触发此函数。
		 * 
		 * 笔记：
		 * 注意以下两句：
		 * 
		 * trace( bytesAvailable );
		 * return;
		 *
		 * 如果插入这两句到本函数第一行，则可以证明 bytesAvailable 是可以积累的，即：
		 * 每次 ProgressEvent.SOCKET_DATA 触发的时候，
		 * socket内部数据如果不被读取，数据会不断积压，延续到下一次 SOCKET_DATA 消息触发。
		 * socket可以看做是一个 ByteArray。
		 * 但是 socket 没有 postion， 或者说 socket 的 postion 在每次读数据之后都归零，而被读取的部分则消失
		 * ByteArray 在读取之后，其内部的数据不会消失，除非主动调用 clear()，这是二者的最大区别。
		 * 每 readInt() 一次，bytesAvailable 减少4（字节），
		 * readShort() 之后，则减少2字节，其它读取函数，以此类推。
		 */
		private function socketDataHandler(event:ProgressEvent):void
		{
			//是否正在读取 ↓
			if(isReading) return;
			
			//读取开始
			isReading = true;
			
			//loop 函数负责读取包头和包体，由于多个包有可能连着一起同时到来，所以 loop 函数可能会执行多次。
			function loop():void{
				
				//★是否包头可读取 ↓
				if(Len==0){
					if(bytesAvailable>=2){
						Len = readUnsignedShort();	//包裹总长度 Len
					}else{
						return;						//如果包头还不够（有可能网络延迟等原因），则return，等待下一次  ProgressEvent.SOCKET_DATA 触发
					}
				}
				
				//★如果包头有效，接着看数据是否可读取 ↓
				if (Len > 0){
					if (bytesAvailable >= Len){
						Body.clear();
						readBytes(Body, 0, Len);	//数据 Body
						Len = 0;
						getMsg(Body);				//★处理数据
						loop();						//如果是多个包连着一起发来给前端（黏包），则继续  loop 函数
					}else{
						return;						//如果将要读取的 body 部分的数据还不够长，则return，等待下一次  ProgressEvent.SOCKET_DATA 触发
					}
				}
			}
			
			//启动 loop 函数
			loop();
			
			//读取结束
			isReading = false;
		}
		/**
		 * 处理从服务端收到的数据
		 */
		private function getMsg(b:ByteArray):void
		{
			trace("====================");
			//trace("cmd :"+b.readUnsignedShort());
			trace("data:"+b.readUTFBytes(b.bytesAvailable));
		}
		
		public function cancelHandler():void
		{
			removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}

		override public function close():void
		{
			super.close();
			trace("主动断开");
		}
		
		/**
		 *当服务端关闭后触发
		 */
		private function closeHandler(event:Event):void
		{
			trace("链接断开");
		}


		private function connectHandler(event:Event):void
		{
			_isrecvProcy=false;
			_retryTime=0;
			_isFirstSend=true;
		}

		/**
		 * IO异常
		 */
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			trace("服务端未打开，或网络故障");
			try{
				this.close();
			}catch (e:Error){
				trace(e);
			}
		}


		/**
		 *安全异常
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			ExternalInterface.call("flashMsg", "联接游戏服务器失败，请刷新当前页面。" + ip + ":" + port);
			try
			{
				if (_retryTime > 3)
				{
					this.close();
					throw new Error("服务器已关闭");
				}
				else
				{
					connect(ip, port);
					_retryTime++
				}
			}
			catch (e:Error)
			{
			}

		}
		private var _cmdMap:CommandMap;
		private var _ccmdParseDic:HashMap;
		private var _scmdParseDic:HashMap;
		private var _cmdArray:Array = [];
		private var isReading:Boolean = false;
		private var Len:int=0;
		private var Body:ByteArray = new ByteArray();
		
		/**
		 * 将二进制数据映射到对象
		 */
		private function mappingObject(valueObject:Object, dataBytes:CustomByteArray):Object
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

		/**
		 *添加某个消息号的监听
		 * @param cmd	消息号
		 * @param args	传两个参数，0为处理函数  1为需要填充的数据对象
		 *
		 */
		public function addCmdListener(cmd:int, hander:Function):void
		{
			if (_cmdArray[cmd] == null)
				_cmdArray[cmd]=[];
			this._cmdArray[cmd].push(hander);
		}

		/**
		 *移除 消息号监听
		 * @param cmd
		 *
		 */
		public function removeCmdListener(cmd:int, listener:Function):void
		{
			var handers:Array=this._cmdArray[cmd];
			if (handers != null && handers.length > 0){
				for (var i:int=(handers.length - 1); i >= 0; i--){
					if (listener == handers[i]){
						handers.splice(i, 1);
					}
				}
			}
		}
		/**
		 * 封装数据发送
		 */
		private function packageData(cmd:uint, object:Object):CustomByteArray
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
		 * 封装消息
		 */
		public function sendMessage(cmd:uint, object:*=null):void
		{
			//todo：命令发送过快处理逻辑
			if (!this.connected)
			{
				trace("还未建立连接 发送命令失败 ");
				return;
			}
			var dataBytes:CustomByteArray=new CustomByteArray();
			if (object != null)
			{
				if (object is Array && object.length > 0)
				{
					var byteArray:CustomByteArray;
					for (var i:int=0; i < object.length; i++)
					{
						byteArray=this.packageData(cmd, object[i]);
						dataBytes.writeBytes(byteArray, 0, byteArray.length);
					}
				}
				else
				{
					byteArray=this.packageData(cmd, object);
					dataBytes.writeBytes(byteArray, 0, byteArray.length);
					
				}
			}
			//装包 
			var sendBytes:CustomByteArray=new CustomByteArray();
			if (_isFirstSend && ip!="127.0.0.1")
			{
				addTgwHead(sendBytes)//第一个包，加tgw包头，服务端将丢弃第一个包
			}
			sendBytes.writeShort(dataBytes.length+2);
			trace("发送总长度"+(dataBytes.length+2)+"的数据");
			sendBytes.writeShort(cmd);
			
			//todo:数组处理逻辑
			//if (object != null && object is Array)
			//{
			//	sendBytes.writeShort(object.length);
			//}
			
			sendBytes.writeBytes(dataBytes, 0, dataBytes.bytesAvailable);
			this.writeBytes(sendBytes);
			this.flush();
			
			byteArray=null;
			object=null;
			dataBytes=null;
			sendBytes=null;
		}
	}
}
