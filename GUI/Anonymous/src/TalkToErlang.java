import java.io.IOException;
import com.ericsson.otp.erlang.*;

import java.util.*;
import java.lang.*;
import java.net.*;

public class TalkToErlang extends Thread
{
	
	OtpNode myNode;
	OtpMbox myMbox;
	OtpMbox myMailBox;
	OtpMbox myMailBox2;
    OtpErlangObject myObject;
    OtpErlangTuple myMsg;
    OtpErlangPid from;
    OtpErlangLong torrentId;
    OtpErlangString value;
    OtpErlangList value2;
    OtpErlangLong tag;
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

			myObject = myMbox.receive();

		myMsg = (OtpErlangTuple) myObject;
		OtpErlangAtom myAtom1 = new OtpErlangAtom("connok");
        from = (OtpErlangPid) myMsg.elementAt(0);
        OtpErlangObject[] reply = new OtpErlangObject[2];
        reply[0] = from;
        reply[1] = myAtom1;
        OtpErlangTuple myTuple1 = new OtpErlangTuple(reply);
        myMbox.send(from, myTuple1);
        System.out.println(myTuple1);
        
	}
	
	public void receive() throws OtpErlangExit, OtpErlangDecodeException, OtpErlangRangeException {
		myMailBox = myNode.createMbox("mailbox2");

		while(true) {
			myObject = myMailBox.receive();
			
			myMsg = (OtpErlangTuple) myObject;
	        from = (OtpErlangPid) myMsg.elementAt(0);
	        torrentId =(OtpErlangLong) myMsg.elementAt(1);
	        System.out.println("JAVAID: " + torrentId);
	        tag = (OtpErlangLong) myMsg.elementAt(2);
	        value = (OtpErlangString) myMsg.elementAt(3);
	        System.out.println(value.stringValue());
	        GUI.setField(torrentId, tag.intValue(), value.stringValue());
	        
		}
	}
	
	public void sendMessage(OtpErlangLong IdLong, String name) throws Exception
    {
        OtpErlangAtom NameAtom = new OtpErlangAtom(name);
        int counter = 1;
        while(counter == 1) {

                OtpErlangObject[] send = new OtpErlangObject[3];
                send[0] = myMbox.self();
                send[1] = IdLong;
                send[2] = NameAtom;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
          }
    }
	
	public void sendMessage(String name1, String name) throws Exception
    {
        OtpErlangAtom NameAtom = new OtpErlangAtom(name1);
        OtpErlangString NameAtom2 = new OtpErlangString(name);
        int counter = 1;
        while(counter == 1) {

                OtpErlangObject[] send = new OtpErlangObject[3];
                send[0] = myMbox.self();
                send[1] = NameAtom;
                send[2] = NameAtom2;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
          }
    }
	public void sendMessage2(Long torrentId, String name, String name2) throws Exception
    {
		OtpErlangLong IdLong = new OtpErlangLong(torrentId);
        OtpErlangAtom myAtom = new OtpErlangAtom(name);
        OtpErlangAtom myAtom2 = new OtpErlangAtom(name2);
        int counter = 1;
        while(counter == 1) {
                OtpErlangObject[] send = new OtpErlangObject[4];
                send[0] = myMbox.self();
                send[1] = IdLong;
                send[2] = myAtom;
                send[3] = myAtom2;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
}
}

	public void sendMessage1(String name) {
		// TODO Auto-generated method stub
		OtpErlangAtom NameAtom = new OtpErlangAtom(name);
        int counter = 1;
        while(counter == 1) {

                OtpErlangObject[] send = new OtpErlangObject[2];
                send[0] = myMbox.self();
                send[1] = NameAtom;
                
                OtpErlangTuple myTuple = new OtpErlangTuple(send);
                System.out.println(myTuple);
                myMbox.send(from, myTuple);
                counter--;
        }
	}

}