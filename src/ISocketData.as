package
{
	public interface ISocketData
	{
		function mappingObject(dataBytes:CustomByteArray):Object;
		function packageData():CustomByteArray;
	}
}