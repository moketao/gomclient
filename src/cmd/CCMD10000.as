package cmd
{
	import common.baseData.Int16;
	
	/**
	 *	 *登陆信息
	 * 协议号:10000
	 c >> s:
	 int:32 平台用户ID
	 int:32 unix时间戳
	 int:16 平台用户账号长度
	 string 平台用户账号
	 int:16 ticket长度
	 string ticket
	 s >> c:
	 int:16
	 0 => 失败
	 1 => 成功
	 * @author Administrator
	 *
	 */
	public class CCMD10000 implements ISocketUp
	{		
		public var a_serverId:Int16;
		public var a_openId:String;
		public var b_openKey:String;
		public var c_pf:String;
		public var d_pfKey:String;
		public var e_invKey:String;
		public var f_itime:String;
		public var g_iopenId:String;
		public var h_checkLogin:String = "HEREWEDONTCHECKOPENKEY";//HEREWEDONTCHECKOPENKEY
//		public var h_checkLogin:String = "";
		public function CCMD10000()
		{
			
		}
		
		public function packageData(b:CustomByteArray):void
		{
			
		}
		
	}
}