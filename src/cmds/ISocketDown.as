package cmds {
	import com.moketao.socket.CustomByteArray;
	public interface ISocketDown {
		function UnPackFrom(dataBytes:CustomByteArray):*;
	}
}
