import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.io.IOException;

import javax.swing.*;

import com.ericsson.otp.erlang.OtpErlangDecodeException;

public class GUI extends JFrame {
	
	JLayeredPane pane;
	protected JLabel menuborder;
	protected ImageIcon border;
	public MenuState currentMenu;
	protected Container conn;
    protected ImageIcon infoBarImg;
    protected ImageIcon buttonImg;
    protected JLabel buttonBoarder;
    protected JButton button1;
    protected JButton button2;
    protected JButton button3;
    protected JButton button4;
    protected JButton button5;
    protected JButton button6;
    protected JMenuBar menuBar;
    protected JMenu fileMenu;
    protected JMenuItem menuItem;
    protected ActionListener openTorrentListener;
    protected ActionListener openUrlTorrentListener;
    protected ActionListener optionMenuItemListener;
    protected ActionListener aboutMenuItemListener;
    protected JMenu settingMenu;
    protected JMenu helpMenu;
    protected JMenuItem openUrlMenuItem;
    protected JMenuItem openMenuItem;
    protected JMenuItem optionMenuItem;
    protected JMenuItem aboutMenuItem;
    protected static JTextArea fileNameField;
    protected static JTextArea fileSizeField;
    protected static JTextArea trackerField;
    protected static JTextArea statusField;
    protected static JTextArea timeLeftField;
    protected static JTextArea downloadSpeedField;
    protected static JTextArea uploadSpeedField;
    protected static JTextArea seedersField;
    protected static JTextArea leechersField;
    protected static JTextArea downloadedField;
    protected static JTextArea uploadedField;
    final JFileChooser fc = new JFileChooser();
    final JFileChooser fc2 = new JFileChooser();
    protected JProgressBar progressBar;
    protected TalkToErlang tte;

	
    public enum MenuState {
        MAIN, START, OPTION, ABOUT
    }
    
    public GUI(TalkToErlang obj) {
        super("Anonymous");
        super.setSize(1024, 550);
        super.setPreferredSize(new Dimension(1024,550));
        super.setIconImage(new ImageIcon("img/titleimg.png").getImage());
        fc2.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
        tte = obj;
        setUpGui();
        
    }
    
    public void displayMenu(MenuState current, final MenuState previous) {

        undisplayMenu(); // we test this position first, before the change of currentMenu, to see how that works out

        currentMenu = current;

        switch (currentMenu) {
        case MAIN: // do all the stuff needed to display the objects unique for main menu (intialize, set all bounds, add to layered pane etc etc)

            //MainBorder
            border = new ImageIcon("img/mainbar.png");
            menuborder = new JLabel(border);
            border = null;
            menuborder.setVisible(true);
            menuborder.setBounds(0, 100, 1024, 425);
            pane.add(menuborder, -1);
            System.out.println("currentmenu = main");
            break;
        case OPTION:

            //MainBorder
            border = new ImageIcon(getClass().getResource("/mainbar.png"));
            menuborder = new JLabel(border);
            border = null;
            menuborder.setVisible(true);
            menuborder.setBounds(0, 0, 1024, 425);
            pane.add(menuborder, 0);
            break;

        case ABOUT:

            //Mainborder
            border = new ImageIcon(getClass().getResource("/mainbar.png"));
            menuborder = new JLabel(border);
            border = null;
            menuborder.setVisible(true);
            menuborder.setBounds(0, 0, 1024, 425);
            pane.add(menuborder, 0);
            break;
        }
    }
    
    /**
     * Undisplays the components to be undisplayed. Sets them to not visible, then
     * to null. At last it calls the garbage collector, making sure that anything not visble
     * is not allocated in the memory.
     */
    public void undisplayMenu() {

        switch (currentMenu) {
        case MAIN: // set all visual objects unique for main menu to null (this will work since this method will be called before the currentMenu is changed)
            menuborder.setVisible(false);
            menuborder = null;
            java.lang.Runtime.getRuntime().gc(); //this comes last just before break
            break;
        case OPTION:
            menuborder.setVisible(false);
            menuborder = null;
            java.lang.Runtime.getRuntime().gc(); //this comes last just before break
            break;

        case ABOUT:
            menuborder.setVisible(false);
            menuborder = null;
            java.lang.Runtime.getRuntime().gc(); //this comes last just before break
            break;
        }

    }
    
    /**
     * Sets up the GUI at startup.
     */
    public void setUpGui() {

        setLayout(new BorderLayout());
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setExtendedState(JFrame.MAXIMIZED_BOTH);
        setResizable(false);

        conn = super.getContentPane();
        
        //layeredpane
        pane = new JLayeredPane();
        pane.setBounds(0, 0, 1024, 600);
        
        
        // main jlabel
        border = new ImageIcon("img/mainbar.png");
        menuborder = new JLabel(border);
        border = null;
        menuborder.setVisible(true);
        menuborder.setBounds(0, 100, 1024, 425);
        pane.add(menuborder, -1);

        currentMenu = MenuState.START;

        //jbutton for Buttons
        buttonImg = new ImageIcon("img/buttonbar");
        buttonBoarder = new JLabel(buttonImg);
        buttonImg = null;
        buttonBoarder.setVisible(true);
        buttonBoarder.setBounds(0,0,1024,100);
        pane.add(buttonBoarder, 0);
        
        button1 = new JButton("Add Torrent");
        button1.setFont(new Font("Raavi", Font.BOLD, 10));
        button1.setVisible(true);
        button1.setBounds(25,25,100,50);
        pane.add(button1,1);
        
        button1.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	int returnval = fc.showOpenDialog(button1);
            	if (returnval == JFileChooser.CANCEL_OPTION) {
            		System.out.println("canceled by user"); 
            	} else {
                	String path;
                	path = fc.getSelectedFile().getAbsolutePath();
                	System.out.println(path);
                	try {
                	tte.sendMessage2("open", path);
            		} catch (Exception e1) {
            			// TODO Auto-generated catch block
            			e1.printStackTrace();
            		}
            	}
            }
        });
        
        button3 = new JButton("Start Torrent");
        button3.setFont(new Font("Raavi", Font.BOLD, 10));
        button3.setVisible(true);
        button3.setBounds(150,25,100,50);
        pane.add(button3,1);
        
        button3.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
				try {
					tte.sendMessage("start");
				} catch (Exception e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
            }
        });
        
        button4 = new JButton("Pause Torrent");
        button4.setFont(new Font("Raavi", Font.BOLD, 10));
        button4.setVisible(true);
        button4.setBounds(275,25,100,50);
        pane.add(button4,1);
        
        button4.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	System.out.println("1");
							try {
								tte.sendMessage("stop");
							} catch (Exception e1) {
								// TODO Auto-generated catch block
								e1.printStackTrace();
							}
            
            }
        });
        
        button5 = new JButton("Delete Torrent");
        button5.setFont(new Font("Raavi", Font.BOLD, 10));
        button5.setVisible(true);
        button5.setBounds(400,25,100,50);
        pane.add(button5,1);
        
        button5.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
				try {
					tte.sendMessage("delete");
				} catch (Exception e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
            }
        });
        
        button6 = new JButton("Set download directory");
        button6.setFont(new Font("Raavi", Font.BOLD, 10));
        button6.setVisible(true);
        button6.setBounds(850,25,130,50);
        pane.add(button6,1);
        
        
        button6.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	int returnval = fc2.showOpenDialog(button6);
            	if (returnval == JFileChooser.CANCEL_OPTION) {
            		System.out.println("canceled by user"); 
            	} else {
                	String path;
                	path = fc2.getSelectedFile().getAbsolutePath();
                	System.out.println(path);
                	try {
                	tte.sendMessage2("dir", path);
            		} catch (Exception e1) {
            			// TODO Auto-generated catch block
            			e1.printStackTrace();
            		}
            	}
            }
        });
        
        //Progress Bar
        
        progressBar = new JProgressBar(0, 100);
        progressBar.setValue(0);
        progressBar.setStringPainted(true);
        progressBar.setVisible(true);
        progressBar.setBounds(20, 430, 980, 50);
        pane.add(progressBar, 2);
        //Need to add the functionality of the progressbar. calculation of task (dl speed/size/pieces needs to be taken in consideration).
        //Add torrent buttons actionListener needs to be connected to this.

        
        //Menubar
        menuBar = new JMenuBar();
        //MenuItems
        fileMenu = new JMenu("File");
        fileMenu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(fileMenu);
        settingMenu = new JMenu("Settings");
        settingMenu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(settingMenu);
        helpMenu = new JMenu("Help");
        helpMenu.setMnemonic(KeyEvent.VK_F);
        menuBar.add(helpMenu);

        //FileMenu Items
        openMenuItem = new JMenuItem("Add Torrent", KeyEvent.VK_N);
//		openMenuItem.addActionListener(openTorrentListener);
        fileMenu.add(openMenuItem);
        
        openMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	int returnval = fc.showOpenDialog(openMenuItem);
            	if (returnval == JFileChooser.CANCEL_OPTION) {
            		System.out.println("canceled by user"); 
            	} else {
                	String path;
                	path = fc.getSelectedFile().getAbsolutePath();
                	System.out.println(path);
                	try {
                	tte.sendMessage2("open", path);
            		} catch (Exception e1) {
            			// TODO Auto-generated catch block
            			e1.printStackTrace();
            		}
            	}
            }
        });
        
        //Setting Menu Items
        optionMenuItem = new JMenuItem("Options", KeyEvent.VK_N);
//		openUrlMenuItem.addActionListener(optionMenuItemListener);
        settingMenu.add(optionMenuItem);
        
        optionMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	JFrame optionFrame = new JFrame("Options");
            	optionFrame.setDefaultCloseOperation(JFrame.DISPOSE_ON_CLOSE);
            	JLabel emptyLabel = new JLabel();
            	optionFrame.setIconImage(new ImageIcon("img/titleimg.png").getImage());
            	optionFrame.getContentPane().add(emptyLabel, BorderLayout.CENTER);
            	optionFrame.setSize(200, 200);
            	optionFrame.setPreferredSize(new Dimension(200,200));
            	optionFrame.setResizable(false);
            	optionFrame.pack();
            	optionFrame.setVisible(true);
            }
        });
        
        //Help Menu Items
        aboutMenuItem = new JMenuItem("About", KeyEvent.VK_N);
//		aboutMenuItem.addActionListener(aboutMenuItemListener);
        helpMenu.add(aboutMenuItem);
        
        aboutMenuItem.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent e) {
            	//about case or new frame?
            }
        });
        
        //TextFields for information about torrent(filename, size, tracker)
        fileNameField = new JTextArea("File name:");
        fileNameField.setFont(new Font("raavi", 0, 20));
        fileNameField.setVisible(true);
        fileNameField.setBorder(null);
        fileNameField.setOpaque(false);
        fileNameField.setEditable(false);
        fileNameField.setBounds(20, 120, 400, 50);
        pane.add(fileNameField, 0);
        
        fileSizeField = new JTextArea("File size:");
        fileSizeField.setFont(new Font("raavi", 0, 20));
        fileSizeField.setVisible(true);
        fileSizeField.setBorder(null);
        fileSizeField.setOpaque(false);
        fileSizeField.setEditable(false);
        fileSizeField.setBounds(20, 170, 400, 50);
        pane.add(fileSizeField, 0);
        
        trackerField = new JTextArea("Tracker:");
        trackerField.setFont(new Font("raavi", 0, 20));
        trackerField.setVisible(true);
        trackerField.setBorder(null);
        trackerField.setOpaque(false);
        trackerField.setEditable(false);
        trackerField.setBounds(20, 220, 400, 50);
        pane.add(trackerField, 0);
        
        statusField = new JTextArea("Status:");
        statusField.setFont(new Font("raavi", 0, 20));
        statusField.setVisible(true);
        statusField.setBorder(null);
        statusField.setOpaque(false);
        statusField.setEditable(false);
        statusField.setBounds(20, 270, 400, 50);
        pane.add(statusField, 0);
        
        timeLeftField = new JTextArea("Time left:");
        timeLeftField.setFont(new Font("raavi", 0, 20));
        timeLeftField.setVisible(true);
        timeLeftField.setBorder(null);
        timeLeftField.setOpaque(false);
        timeLeftField.setEditable(false);
        timeLeftField.setBounds(800, 120, 200, 50);
        pane.add(timeLeftField, 0);
        
        //seeders,leechers,download & upload speeds
        downloadSpeedField = new JTextArea("Download speed:");
        downloadSpeedField.setFont(new Font("raavi", 0, 20));
        downloadSpeedField.setVisible(true);
        downloadSpeedField.setBorder(null);
        downloadSpeedField.setOpaque(false);
        downloadSpeedField.setEditable(false);
        downloadSpeedField.setBounds(20, 400, 200, 50);
        pane.add(downloadSpeedField, 0);
        
        uploadSpeedField = new JTextArea("Upload speed:");
        uploadSpeedField.setFont(new Font("raavi", 0, 20));
        uploadSpeedField.setVisible(true);
        uploadSpeedField.setBorder(null);
        uploadSpeedField.setOpaque(false);
        uploadSpeedField.setEditable(false);
        uploadSpeedField.setBounds(260, 400, 200, 50);
        pane.add(uploadSpeedField, 0);
        
        seedersField = new JTextArea("Seeders:");
        seedersField.setFont(new Font("raavi", 0, 20));
        seedersField.setVisible(true);
        seedersField.setBorder(null);
        seedersField.setOpaque(false);
        seedersField.setEditable(false);
        seedersField.setBounds(500, 400, 200, 50);
        pane.add(seedersField, 0);
        
        leechersField = new JTextArea("Leechers:");
        leechersField.setFont(new Font("raavi", 0, 20));
        leechersField.setVisible(true);
        leechersField.setBorder(null);
        leechersField.setOpaque(false);
        leechersField.setEditable(false);
        leechersField.setBounds(740, 400, 200, 50);
        pane.add(leechersField, 0);
        
        downloadedField = new JTextArea("Downloaded:");
        downloadedField.setFont(new Font("raavi", 0, 20));
        downloadedField.setVisible(true);
        downloadedField.setBorder(null);
        downloadedField.setOpaque(false);
        downloadedField.setEditable(false);
        downloadedField.setBounds(800, 170, 200, 50);
        pane.add(downloadedField, 0);
        
        uploadedField = new JTextArea("Uploaded:");
        uploadedField.setFont(new Font("raavi", 0, 20));
        uploadedField.setVisible(true);
        uploadedField.setBorder(null);
        uploadedField.setOpaque(false);
        uploadedField.setEditable(false);
        uploadedField.setBounds(800, 220, 200, 50);
        pane.add(uploadedField, 0);
        
        //end.
        displayMenu(MenuState.MAIN, MenuState.MAIN);
        conn.add(pane);
        super.setJMenuBar(menuBar);
        super.pack();
        super.setVisible(true);
    }
    	public static void setField(String torrentId, int tag,String value) {
    		switch (tag) {
    		case 0: fileNameField.setText("File name: " + value);
    		break;
    		case 1: fileSizeField.setText("File size: " + value + " Mb");
    		break;
    		case 2: trackerField.setText("Tracker: " + value);
    		break;
    		case 3: downloadSpeedField.setText("Download speed: " + value +" Kb/s");
    		break;
    		case 4: uploadSpeedField.setText("Upload speed: " + value +" Kb/s");
    		break;
    		case 5: seedersField.setText("Seeders: " + value);
    		break;
    		case 6: leechersField.setText("Leechers: " + value);
    		break;
    		case 7: downloadedField.setText("Downloaded: " +value + "Mb");
    		break;
    		case 8: uploadedField.setText("Downloaded: " +value + "Mb");
    		break;
    		case 10: statusField.setText("Status: " +"Active");
    		break;
    		case 11: statusField.setText("Status: " +"Stopped");
    		break;
    		case 13: statusField.setText("Status: " +"Paused");
    		break;
    		}
    	}

    
    

}
