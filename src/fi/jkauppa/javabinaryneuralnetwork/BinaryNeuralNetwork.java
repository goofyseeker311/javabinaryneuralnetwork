package fi.jkauppa.javabinaryneuralnetwork;

import java.util.ArrayList;

public class BinaryNeuralNetwork {

	public BinaryNeuralNetwork() {
		System.out.println("init.");
	}
	
	public void run() {
		System.out.println("run.");
		System.out.println("done.");
	}
	
	public static void main(String[] args) {
		System.out.println("BinaryNeuralNetwork v0.0.3");
		BinaryNeuralNetwork app = new BinaryNeuralNetwork();
		app.run();
		System.out.println("exit.");
	}
	
	private static class Network {
		ArrayList<Node> nodelist = new ArrayList<Node>();
	}
	
	private static class Node {
		public byte data = 0;
		public byte weight = 0;
		public Node out = null;
	}

}
