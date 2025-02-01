package fi.jkauppa.javabinaryneuralnetwork;

public class BinaryNeuralNetwork {

	public BinaryNeuralNetwork() {
		System.out.println("init.");
	}
	
	public void run() {
		System.out.println("run.");
		System.out.println("done.");
	}
	
	public static void main(String[] args) {
		BinaryNeuralNetwork app = new BinaryNeuralNetwork();
		app.run();
		System.out.println("exit.");
	}
	
	private class Network {
		
	}
	
	private class Node {
		
	}

}
