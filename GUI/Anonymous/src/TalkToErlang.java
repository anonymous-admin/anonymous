import java.io.IOException;
import com.ericsson.otp.erlang.OtpErlangAtom;
import com.ericsson.otp.erlang.OtpErlangDecodeException;
import com.ericsson.otp.erlang.OtpErlangExit;
import com.ericsson.otp.erlang.OtpErlangInt;
import com.ericsson.otp.erlang.OtpErlangLong;
import com.ericsson.otp.erlang.OtpErlangObject;
import com.ericsson.otp.erlang.OtpErlangPid;
import com.ericsson.otp.erlang.OtpErlangRangeException;
import com.ericsson.otp.erlang.OtpErlangString;
import com.ericsson.otp.erlang.OtpErlangTuple;
import com.ericsson.otp.erlang.OtpMbox;
import com.ericsson.otp.erlang.OtpNode;
import java.util.*;
import java.lang.*;
import java.net.*;

public class TalkToErlang extends Thread
{
	
	OtpNode myNode;
	OtpMbox myMbox;
	OtpMbox myMailBox;
    OtpErlangObject myObject;
    OtpErlangTuple myMsg;
    OtpErlangPid from;
    OtpErlangString torrentId;
    OtpErlangString value;
    OtpErlangLong tag;
//    OtpErlangInt tag;
    String computerName;
    
	public TalkToErlang() {
	
		try {
			myNode = new OtpNode("javaNode");
			myMbox = myNode.createMbox("mailbox");
		} catch (IOException e) {
			e.printStackTrace();
		}    	
	}
	
	public void startConnection() throws OtpErlangExit, OtpErlangDecodeException, UnknownHostException {
		computerName = InetAddress.getLocalHost().getHostName();
		if (myNode.ping("lol@"+computerName,2000)) {
			System.out.println("remote is up");
			}
			else {
			System.out.println("remote is not up");
			}
//
//			myObject = myMbox.receive();
//
//		myMsg = (OtpErlangTuple) myObject;
//		OtpErlangAtom myAtom1 = new OtpErlangAtom("connok");
//        from = (OtpErlangPid) myMsg.elementAt(0);
//        OtpErlangObject[] reply = new OtpErlangObject[2];
//        reply[0] = from;
//        reply[1] = myAtom1;
//        OtpErlangTuple myTuple1 = new OtpErlangTuple(reply);
//        myMbox.send(from, myTuple1);
//        System.out.println(myTuple1);
        
	}
	
	public void receive() throws OtpErlangExit, OtpErlangDecodeException, OtpErlangRangeException {
		myMailBox = myNode.createMbox("mailbox2");

		while(true) {
			System.out.println("lol1");
			myObject = myMailBox.receive();
			
			myMsg = (OtpErlangTuple) myObject;
	        from = (OtpErlangPid) myMsg.elementAt(0);
	        torrentId =(OtpErlangString) myMsg.elementAt(1);
	        tag = (OtpErlangLong) myMsg.elementAt(2);
	        value = (OtpErlangString) myMsg.elementAt(3);
	        System.out.println(value.stringValue());
	        GUI.setField(torrentId.stringValue(), tag.intValue(), value.stringValue());
	        
		}
	}
	
	public void sendMessage(String name) throws Exception
    {
        OtpErlangAtom myAtom = new OtpErlangAtom(name);
        int counter = 1;
        while(counter == 1) {

                OtpErlangObject[] send = new OtpErlangObject[2];
                send[0] = myMbox.self();
                send[1] = myAtom;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
}
}
	public void sendMessage2(String name, String name2) throws Exception
    {
        OtpErlangAtom myAtom = new OtpErlangAtom(name);
        OtpErlangAtom myAtom2 = new OtpErlangAtom(name2);
        int counter = 1;
        while(counter == 1) {
                OtpErlangObject[] send = new OtpErlangObject[3];
                send[0] = myMbox.self();
                send[1] = myAtom;
                send[2] = myAtom2;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
}
}
}