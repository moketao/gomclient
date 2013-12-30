package
{
	import flash.utils.IDataInput;
	
	import game.socket.CustomByteArray;

	public interface ISocketIn
	{
		function mappingObject(dataBytes:CustomByteArray):Object;
	}
	
	
}