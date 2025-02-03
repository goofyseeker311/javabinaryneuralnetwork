package fi.jkauppa.javabinaryneuralnetwork;

public class TestNetwork {
	private BinaryNeuralNetwork[] networks = null;

	public TestNetwork() {
		System.out.println("init.");
	}
	
	public void run() {
		System.out.println("run.");
		System.out.println("done.");
	}
	
	public static void main(String[] args) {
		System.out.println("BinaryNeuralNetwork v0.0.4");
		TestNetwork app = new TestNetwork();
		app.run();
		System.out.println("exit.");
	}

}
