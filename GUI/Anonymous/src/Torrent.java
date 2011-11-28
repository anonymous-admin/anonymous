
public class Torrent {

	protected int seeders;
	protected int leechers;
	protected int downloadSpeed;
	protected int uploadSpeed;
	protected int timeLeft;
	protected int fileSize;
	protected String fileName;
	protected String tracker;
	protected String status;
	
	public Torrent() {
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
	public int getFileSize() {
		return fileSize;
	}
	public void setFileSize(int fileSize) {
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

	
}

