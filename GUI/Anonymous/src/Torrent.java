import java.awt.Color;
import java.util.ArrayList;

import javax.swing.JButton;

import com.ericsson.otp.erlang.OtpErlangAtom;


public class Torrent {

	protected OtpErlangAtom id;
	protected ArrayList<String> files;
	protected int seeders;
	protected int leechers;
	protected int downloadSpeed;
	protected int uploadSpeed;
	protected double downloaded;
	protected double uploaded;
	protected int timeLeft;
	protected long fileSize;
	protected String fileName;
	protected String tracker;
	protected String status;
	protected boolean isActive;
	protected int percentage;
	protected JButton button;
	
	public Torrent() {
	}
	
	public Torrent(OtpErlangAtom id) {
		this.id = id;
		this.files = new ArrayList<String>();
	}

	public Torrent(int seeders, int leechers, int downloadSpeed, int uploadSpeed,
			int timeLeft, int fileSize, String fileName, String tracker,
			String status) {
		this.seeders = seeders;
		this.leechers = leechers;
		this.downloadSpeed = downloadSpeed;
		this.uploadSpeed = uploadSpeed;
		this.timeLeft = timeLeft;
		this.fileSize = fileSize;
		this.fileName = fileName;
		this.tracker = tracker;
		this.status = status;
		
	}
	
	
	
	public int getSeeders() {
		return seeders;
	}
	public void setSeeders(int seeders) {
		this.seeders = seeders;
	}
	public int getLeechers() {
		return leechers;
	}
	public void setLeechers(int leechers) {
		this.leechers = leechers;
	}
	public int getDownloadSpeed() {
		return downloadSpeed;
	}
	public void setDownloadSpeed(int downloadSpeed) {
		this.downloadSpeed = downloadSpeed;
	}
	public int getUploadSpeed() {
		return uploadSpeed;
	}
	public void setUploadSpeed(int uploadSpeed) {
		this.uploadSpeed = uploadSpeed;
	}
	public int getTimeLeft() {
		return timeLeft;
	}
	public void setTimeLeft(int timeLeft) {
		this.timeLeft = timeLeft;
	}
	public long getFileSize() {
		return fileSize;
	}
	public void setFileSize(long fileSize) {
		this.fileSize = fileSize;
	}
	public String getFileName() {
		return fileName;
	}
	public void setFileName(String fileName) {
		this.fileName = fileName;
	}
	public String getTracker() {
		return tracker;
	}
	public void setTracker(String tracker) {
		this.tracker = tracker;
	}
	public String getStatus() {
		return status;
	}
	public void setStatus(String status) {
		this.status = status;
	}

	public OtpErlangAtom getId() {
	    return id;
	}
	
	public void setId(OtpErlangAtom id) {
		this.id = id;
	}
	
	public ArrayList<String> getFiles() {
		return files;
	}
	
	public void setFiles(ArrayList<String> files) {
		this.files = files;
	}
	
	public boolean isActive() {
		return isActive;
	}
	
	public void setActive(boolean active) {
		this.isActive = active;
	}
	
	public double getDownloaded() {
		return downloaded;
	}
	
	public void setDownloaded(double downloaded) {
		this.downloaded = downloaded;
	}
	
	public int getPercentage() {
		return percentage;
	}
	
	public void setPercentage(int percentage) {
		this.percentage = percentage;
	}
	
	public double getUploaded() {
		return uploaded;
	}
	
	public void setUploaded(double uploaded) {
		this.uploaded = uploaded;
	}
	
	public void setTorrentButton(final Torrent torrent, int index) {
		int x = (index*100)+3;
		this.button = new JButton();
		this.button.setVisible(true);
		this.button.setToolTipText("Display torrent: " + this.getFileName());
		this.button.setContentAreaFilled(true);
		this.button.setText(this.getFileName());
		this.button.setBackground(Color.ORANGE);
		this.button.setBounds(x,103,100,25);
	}
	
	public JButton getTorrentButton() {
		return this.button;
	}
}

