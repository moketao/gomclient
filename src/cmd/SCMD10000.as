package cmd
{
	import common.baseData.Int16;
	

	/**
	 *登陆信息
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
	public class SCMD10000 implements ISocketDown
	{
		public var a_state:Int16;

		public function SCMD10000()
		{
			
		}
		
		public function UnPackFrom(dataBytes:CustomByteArray):*
		{
//			a_state = dataBytes.readInt16();
			return this;
		}
		

	}
}