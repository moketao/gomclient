package
{
	import flash.utils.IDataOutput;
	
	import game.socket.CustomByteArray;

	/**
	 * Socket 发送 
	 * @author ASIMO
	 * 
	 */	
	public interface ISocketOut
	{
		
		function packageData():CustomByteArray;
	}
	
	
}