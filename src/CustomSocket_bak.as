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
	public class CustomSocketbak extends Socket
	{
		public static const ERROR:String="socket_error";
		//		消息号数组
		private var _cmdArray:Array;
		//		内容长度
		private var _contentLen:int;
		//		端口
		public static var port:int;
		//		http端口
		public var httpPort:int;
		//		临时用角色ID
		public var accountId:int;
		public static const tgwStrPre:String = "tgw_l7_forward\r\nHost: ";
		public static const tgwStrEnd:String = "\r\n\r\n";
		public static var ip:String;
		private static var one:CustomSocket;
		/**
		 * 包头长度
		 */
		private const HEADLENGTH:int=4;//cmd长度(2)+body长度(2) ★有坑!!!

		/**
		 *是否已接收到策略字串
		 */
		private var _isrecvProcy:Boolean=false;

		private var _retryTime:int=0;
		private var sendIdle:Dictionary;
		private var deadIdle:Dictionary;


		/**
		 *构造函数
		 *
		 */
		public function CustomSocketbak()
		{
			super(null, 0);
			if (one != null)
			{
				throw new Error("单例模式类")
			}

			//this.endian=Endian.LITTLE_ENDIAN;
			//this.endian=Endian.BIG_ENDIAN;
			_cmdArray=[];
			_cmdMap=CommandMap.getInstance();
			_ccmdParseDic=new HashMap();
			_scmdParseDic=new HashMap();
			initSendIdle();
			initDeadIdle();
		}

		/**
		 *添加命令的调用间隔
		 * idle间隔毫秒数
		 */
		private function initSendIdle():void
		{
			sendIdle=new Dictionary();
		}

		/**
		 *人物死亡后可以调用的命令
		 *
		 */
		private function initDeadIdle():void
		{
			deadIdle=new Dictionary();
			deadIdle[20004]=[20004];
			deadIdle[10006]=[10006];
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
		 *
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
		 * @param sendBytes
		 */
		private function addTgwHead(sendBytes:CustomByteArray):void
		{
			var tgwStr:String=tgwStrPre + ip + ":" + port + tgwStrEnd;
			sendBytes.writeMultiByte(tgwStr, "GBK");
			_isFirstSend=false;
		}

		private var _isFirstSend:Boolean=true;
		/**
		 * 封装消息
		 * @param cmd	消息消息号
		 * @param object 消息内容
		 *
		 */
		public function sendMessage(cmd:uint, object:*=null):void
		{
			//if(WillBeTrace(cmd))trace("前端发送协议"+cmd);
			//trace("前端发送协议"+cmd);
			if (!idleFilter(cmd))
				return;
			if (!this.connected)
			{
				//throw new Error("还未建立连接 发送命令失败 " + cmd)
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
			trace("长度"+(dataBytes.length+2));
			sendBytes.writeShort(cmd);

//			if (object != null && object is Array)
//			{
//				sendBytes.writeShort(object.length);
//			}

			sendBytes.writeBytes(dataBytes, 0, dataBytes.bytesAvailable);
			this.writeBytes(sendBytes);
			this.flush();

			byteArray=null;
			object=null;
			dataBytes=null;
			sendBytes=null;
		}

		private function idleFilter(cmd:uint):Boolean
		{
			var o:Object=sendIdle[cmd];
			if (o != null)
			{
				if ((new Date().getTime() - o.last) > o.idle)
				{
					o.last=new Date().getTime();
					return true;
				}
				else
				{
					throw new Error("命令发送太快了" + cmd);
					return false;
				}
			}
			return true;
		}

		private function deadFilter(cmd:uint):Boolean
		{
			var o:Object=deadIdle[cmd];
			if (o != null)
			{
				throw new Error("死亡后调用了" + cmd);
				return false
			}
			return true;
		}


		/**
		 * 封装数据发送
		 * @param object 需要发送的参数对象
		 * @return
		 *
		 */
		private function packageData(cmd:uint, object:Object):CustomByteArray
		{
			if (object is ISocketUp)
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
		 *配置socket监听事件
		 *
		 */
		private function configureListeners():void
		{
			addEventListener(Event.CLOSE, closeHandler);
			addEventListener(Event.CONNECT, connectHandler);
			addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
			addEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}

		public function cancelHandler():void
		{
			removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}

		override public function close():void
		{
			super.close();
			//throw new Error(ERROR, {code: 1});
			trace("主动断开");
		}
		
		/**
		 *当服务端关闭后触发
		 * @param event
		 *
		 */
		private function closeHandler(event:Event):void
		{
			//throw new Error(ERROR, {code: 1});
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
		 * @param event
		 *
		 */
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			//throw new Error(ERROR, {code: 2});
			trace("服务端未打开，或网络故障");
			try
			{
				this.close();
			}
			catch (e:Error)
			{
				
			}
		}


		/**
		 *安全异常
		 * @param event
		 *
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			throw new Error(ERROR, {code: 3});
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
		private var _readDataFlag:Boolean=false;
		private var _cashDataArray:Array=[];

		public static var cost:Number=0;
		public static var cmd:int=0;
		public static var recordTime:Number=0;
		private var _cashBytes:CustomByteArray;
		private var _cmdMap:CommandMap;
		private var _ccmdParseDic:HashMap;
		private var _scmdParseDic:HashMap;

		/**
		 *收到服务端发送数据触发
		 * @param event
		 *
		 */
		private function socketDataHandler(event:ProgressEvent):void
		{
			//    	try{      
			var bytes:CustomByteArray=new CustomByteArray(); //开辟缓冲区
			this.readBytes(bytes, 0, this.bytesAvailable); //将数据读入内存缓冲区
			_cashDataArray.push(bytes);
			bytes.traceBytes();

			if (!_isrecvProcy)
			{
				//过滤策略字串
				var newbytes:ByteArray=new ByteArray();
				newbytes.writeBytes(bytes);
				newbytes.position=0;

				var s:String=newbytes.readUTFBytes(newbytes.bytesAvailable)
				if (s.indexOf("</cross-domain-policy>") > 0)
				{
					//"现在收到策略文件"+getTimer();
					_cashDataArray=[];
					if (bytes.length > 89)
					{
						var _bytes:CustomByteArray=new CustomByteArray();
						_bytes.writeBytes(bytes, 89);
						_bytes.position=0;
						bytes=_bytes;
						_cashDataArray=[];
						_cashDataArray.push(bytes);
							//_isrecvProcy=true;
					}
					else
					{
						throw new Error("策略字串 " + s);
						return;
					}
				}
			}

			if (!_readDataFlag) //如果当前没有在数据处理中 将开始处理数据，否则等待处理
			{
				_readDataFlag=true; //设置状态标志为处理中
				handleCashData(); //开始处理数据
			}

			event=null;
			bytes=null;

		}

		private function handleCashData():void
		{
			//    	try{    	

			if (_cashDataArray.length <= 0) //当前数据缓冲区为空
			{
				_readDataFlag=false; //将处理进行中状态标志为 否
				return;
			}

			var bytesArray:CustomByteArray=this._cashDataArray.shift(); //如果不为空 将读取队列头数据
			bytesArray.position=0; //将字节数组指针还原 	
			//			如果上一次缓存的字节数组里面有东西，将读取出来和这一次进行拼接
			if (_cashBytes != null && _cashBytes.bytesAvailable > 0)
			{
				var dataBytes:CustomByteArray=new CustomByteArray();
				_cashBytes.readBytes(dataBytes, 0, _cashBytes.bytesAvailable);
				bytesArray.readBytes(dataBytes, dataBytes.length, bytesArray.bytesAvailable);
				_cashBytes=null;
				bytesArray=dataBytes;
				bytesArray.position=0; //将字节数组指针还原 	
				dataBytes=null;
			}
			if (_contentLen == 0 && bytesArray.bytesAvailable < 2) //当前数据不够需要的数据长度,且还未读取过包长度  将缓存数据
			{
				if (_cashBytes == null)
				{
					_cashBytes=new CustomByteArray(); //开辟缓存数据
				}
				bytesArray.readBytes(_cashBytes, _cashBytes.length, bytesArray.bytesAvailable); //将当前数据放入缓冲区
				bytesArray=null;
				handleCashData(); //重新开始去队列数据				
			}
			else
			{
				//将字节数组转换成数据
				getBytes(bytesArray);
				dataBytes=null;
				bytesArray=null;
			}


		}

		public function getBytes(bytesArray:CustomByteArray):void
		{
			bytesArray.traceBytes();
			bytesArray.position = 0;
			bytesArray.position = 0;
			bytesArray.position = 0;
			// 	读取内容长度
			if (_contentLen == 0)
				_contentLen=bytesArray.readUnsignedShort() - 2; //计算出当前还需要的数据包长度 UnsignedShort为2个字节
			if (bytesArray.bytesAvailable < _contentLen) //查看当前长度是否小于 需要的长度  
			{ //数据包长度不足

				if (_cashBytes == null) //开辟缓冲区 存取长度
				{
					_cashBytes=new CustomByteArray();
				}
				bytesArray.readBytes(_cashBytes, _cashBytes.length, bytesArray.bytesAvailable); //将数据放入缓冲区
				bytesArray=null;
				handleCashData(); //继续读取队列数据

			}
			else
			{
				//        读取两个字节的消息号

				if (_isrecvProcy == false)
				{
					_isrecvProcy=true;
				}
				var cmd:int=bytesArray.readUnsignedShort();
				if(cmd==14009){
					var i:int = 5;
				}
				_contentLen-=2; //减去协议号所占的2个字节
				//if(ConfigManager.isDebug)
//				trace("---------收到服务端数据,消息号：", cmd, "      总长度:", _contentLen + HEADLENGTH, " 字节"+getTimer());
				var realDatas:CustomByteArray=new CustomByteArray(); //开辟数据区域，将实际数据读取出来
				if (_contentLen != 0)
				{
					bytesArray.readBytes(realDatas, 0, _contentLen);
				}
				receiveData(cmd, realDatas);
				_contentLen=0;
				realDatas=null;

				//        如果缓冲区还有数据，则继续读
				if (bytesArray.bytesAvailable >= 2)
				{

					getBytes(bytesArray);

				}
				else
				{

					if (bytesArray.bytesAvailable > 0)
					{
						if (_cashBytes == null)
						{
							_cashBytes=new CustomByteArray();
						}
						bytesArray.readBytes(_cashBytes, _cashBytes.length, bytesArray.bytesAvailable);
							//bytesArray.readBytes(_cashBytes, _cashBytes.length, 0)
					}
					_readDataFlag=false;
					bytesArray=null;
					handleCashData();

				}

			}

		}

		/**
		 *处理收到的服务端发送过来的消息
		 * @param cmd  消息号
		 * @param length 长度
		 *
		 */

		private function receiveData(cmd:int, dataBytes:CustomByteArray):void
		{
			var hander:Array=_cmdArray[cmd];
			
			dataBytes.position = 0;
			trace(dataBytes.readUTFBytes(dataBytes.length));
			
			if (hander == null || hander.length <= 0)
			{
				return;
			}
			var valueObject:Object; //获取该消息号对应的valueObject对象
			var valueObjArray:Object; //将发送过来的数据映射到对象里面去
			valueObject=this._cmdMap.getCMDObject(cmd); //根据消息协议号映射对象
			if (_cmdMap.getWaitCMDObject(cmd) > 0)
			{
				throw new Error("PopUpManager.removePopUp(PopUpManager.getWindow(Loading))");
			}

			if (valueObject == null) //如果没有配置对象时
			{
				throw new Error("没有配置该协议对应的类 cmd=" + cmd);
			}
			else
			{
				//			如果没有映射对象	
				if (dataBytes.bytesAvailable > 0)
				{
					try{
						valueObjArray=this.mappingObject(valueObject, dataBytes);
					}catch(e:Error){
						valueObject=null;
						hander=null;
						trace("★协议报错，前后端协议对不上:",e.getStackTrace());
						return;
					}
				}
				else
				{
					valueObjArray=null;
				}
			}
//			trace("--------> 后端返回： "+cmd+" ,处理函数 "+hander.length+"个");
			//if(WillBeTrace(cmd)){
				//trace("--------> 后端返回： "+cmd+" ,处理函数有"+hander.length+"个");
			//}
			for each (var fun:Function in hander)
			{
//				var d1:int=getTimer();
				if (valueObjArray == null)
				{
					fun();
				}
				else
				{
					fun(valueObjArray);
				}
			}
			CustomSocket.cmd=cmd;
			valueObject=null;
			hander=null;
		}

		/**
		 * 将二进制数据映射到对象
		 * @param valueObject  需要映射的对象
		 * @return
		 *
		 */
		private function mappingObject(valueObject:Object, dataBytes:CustomByteArray):Object
		{

			if (valueObject is ISocketDown)
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
			if (handers != null && handers.length > 0)
			{
				for (var i:int=(handers.length - 1); i >= 0; i--)
				{
					if (listener == handers[i])
					{
						handers.splice(i, 1);
					}
				}
			}

		}

	}
}
