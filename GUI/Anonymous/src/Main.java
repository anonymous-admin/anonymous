
public class Main {
    public static void main(String[] args) {
    	(new TalkToErlang()).start();
    	TalkToErlang tte = new TalkToErlang();
    	new GUI(tte);
    	
    	try {
    		Thread.sleep(2000);
			tte.startConnection();
			tte.receive();
		} catch (Exception e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
    }
}
