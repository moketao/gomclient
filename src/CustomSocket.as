package {
	import com.ericfeminella.collections.HashMap;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.external.ExternalInterface;
	import flash.net.Socket;
	import flash.utils.ByteArray;
	
	import cmds.CommandMap;
	
	import common.baseData.Pack;
	
	import mycom.Alert;


	//	import uisystem.view.UiSystemMediator;	

	/**自定义socket 数据通信管理器
	 *
	 * @author liudisong
	 *
	 */
	public class CustomSocket extends Socket {
		public static var ip:String; //IP
		public static var port:int; //端口
		private static const tgwStrPre:String="tgw_l7_forward\r\nHost: "; //腾讯网关第一个包需要发送的内容1
		private static const tgwStrEnd:String="\r\n\r\n"; //腾讯网关第一个包需要发送的内容2
		private static var one:CustomSocket; //单例
		private var retryTimes:int=0; //重新连接的次数
		private var firstPack:Boolean=true; //是否第一个发送给后端的包

		/**
		 *构造函数
		 */
		public function CustomSocket() {
			super(null, 0);
			if (one != null) {
				throw new Error("单例模式类")
			}
			_cmdMap=CommandMap.getInstance();
			_ccmdParseDic=new HashMap();
			_scmdParseDic=new HashMap();
		}

		/**
		 * 单例
		 */
		public static function getInstance():CustomSocket {
			if (one == null) {
				one=new CustomSocket();
			}
			return one;
		}

		/**
		 *启动自定义socket
		 */
		public function start(_ip:String, _port:int):void {
			ip=_ip;
			port=_port;
			this.configureListeners();
			super.connect(ip, port);
		}

		/**
		 * 针对QQ平台，添加TGW负载均衡包头
		 */
		private function addTgwHead(sendBytes:CustomByteArray):void {
			var tgwStr:String=tgwStrPre + ip + ":" + port + tgwStrEnd;
			sendBytes.writeMultiByte(tgwStr, "GBK");
			firstPack=false;
		}

		/**
		 *配置socket监听事件
		 */
		private function configureListeners():void {
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
		private function socketDataHandler(event:ProgressEvent):void {
			//loop 函数负责读取包头和包体，由于多个包有可能连着一起同时到来，所以 loop 函数可能会执行多次。
			function loop():void {

				//★是否包头可读取 ↓
				if (Len == 0) {
					if (bytesAvailable >= 2) {
						Len=readUnsignedShort(); //包裹总长度 Len
					} else {
						return; //如果包头还不够（有可能网络延迟等原因），则return，等待下一次  ProgressEvent.SOCKET_DATA 触发
					}
				}

				//★如果包头有效，接着看数据是否可读取 ↓
				if (Len > 0) {
					if (bytesAvailable >= Len) {
						Body.clear();
						readBytes(Body, 0, Len); //数据 Body
						Len=0;
						getMsg(Body); //★处理数据
						loop(); //★如果是多个包连着一起发来给前端（黏包），则继续  loop 函数
					} else {
						return; //如果将要读取的 body 部分的数据还不够长，则return，等待下一次  ProgressEvent.SOCKET_DATA 触发
					}
				}
			}

			//启动 loop 函数
			loop();
		}

		/**
		 * 处理从服务端收到的数据
		 */
		private function getMsg(b:CustomByteArray):void {
			var num:int = b.readUnsignedShort();
			var vo:*;
			if(b.bytesAvailable>0){
				var ob:Object = CommandMap.getCmdOB(num);
				var i:ISocketDown = ob as ISocketDown;
				vo = i.UnPackFrom(b);
			}
			var hander:Array=_cmdArray[num];
			if (hander == null || hander.length <= 0) return;
			for each (var fun:Function in hander){
				if (vo == null){
					fun();
				}else{
					fun(vo);
				}
			}
		}

		public function cancelHandler():void {
			removeEventListener(ProgressEvent.SOCKET_DATA, socketDataHandler);
		}

		override public function close():void {
			super.close();
			trace("主动断开");
		}

		/**
		 *当服务端关闭后触发
		 */
		private function closeHandler(event:Event):void {
			trace("链接断开");
		}


		private function connectHandler(event:Event):void {
			retryTimes=0;
			firstPack=true;
		}

		/**
		 * IO异常
		 */
		private function ioErrorHandler(event:IOErrorEvent):void {
			trace("服务端未打开，或网络故障");
			try {
				this.close();
			} catch (e:Error) {
				trace(e);
			}
		}


		/**
		 *安全异常
		 */
		private function securityErrorHandler(event:SecurityErrorEvent):void {
			ExternalInterface.call("flashMsg", "联接游戏服务器失败，请刷新当前页面。" + ip + ":" + port);
			try {
				if (retryTimes > 3) {
					this.close();
					throw new Error("服务器已关闭");
				} else {
					connect(ip, port);
					retryTimes++
				}
			} catch (e:Error) {
			}

		}
		private var _cmdMap:CommandMap;
		private var _ccmdParseDic:HashMap;
		private var _scmdParseDic:HashMap;
		private var _cmdArray:Array=[];
		private var isReading:Boolean=false;
		private var Len:int=0;
		private var Body:CustomByteArray=new CustomByteArray();


		/**
		 *添加某个消息号的监听
		 * @param cmd	消息号
		 * @param args	传两个参数，0为处理函数  1为需要填充的数据对象
		 */
		public function addCmdListener(cmd:int, hander:Function):void {
			if (_cmdArray[cmd] == null)
				_cmdArray[cmd]=[];
			
			//看是否已经添加，如果已经添加，则不再重复添加
			var arr:Array = _cmdArray[cmd];
			for (var i:int = 0; i < arr.length; i++) {
				var f:Function = arr[i] as Function;
				if(f==hander) return;
			}
			
			this._cmdArray[cmd].push(hander);
		}

		/**
		 *移除 消息号监听
		 */
		public function removeCmdListener(cmd:int, listener:Function):void {
			var handers:Array=this._cmdArray[cmd];
			if (handers != null && handers.length > 0) {
				for (var i:int=(handers.length - 1); i >= 0; i--) {
					if (listener == handers[i]) {
						handers.splice(i, 1);
					}
				}
			}
		}

		/**
		 * 封装消息
		 */
		public function sendMessage(cmd:uint, object:*=null):void {
			//todo：命令发送过快处理逻辑
			if (!this.connected) {
				trace("还未建立连接 发送命令失败 ");
				return;
			}
			var dataBytes:CustomByteArray=new CustomByteArray();
			if (object != null) {
				var Ipack:ISocketUp=object as ISocketUp;
				if (!Ipack){
					Alert.show("sendMessage 的第二个参数必须是 ISocketUp");
					return;
				}
				Ipack.PackInTo(dataBytes);
				dataBytes.position=0;
			}

			//装包 
			var sendBytes:CustomByteArray=new CustomByteArray();
			if (firstPack && ip != "127.0.0.1") {
				addTgwHead(sendBytes) //第一个包，加tgw包头，服务端将丢弃第一个包
			}
			sendBytes.writeShort(dataBytes.length + 2); //包总长=数据长度+协议16长度（一个16位无符号正整数）
			sendBytes.writeShort(cmd); //写入协议号
			sendBytes.writeBytes(dataBytes); //写入数据
			this.writeBytes(sendBytes);
			this.flush();
		}
	}
}
