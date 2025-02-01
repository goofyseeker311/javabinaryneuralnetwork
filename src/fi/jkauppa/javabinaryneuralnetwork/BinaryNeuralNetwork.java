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
		System.out.println("BinaryNeuralNetwork v0.0.2");
		BinaryNeuralNetwork app = new BinaryNeuralNetwork();
		app.run();
		System.out.println("exit.");
	}
	
	private static class Network {
		ArrayList<Node> nodelist = new ArrayList<Node>();
	}
	
	private static class Node {
		public int data = 0;
		public int mask = 0;
		public int weight = 0;
		public Node out = null;
		public int outbit = 0;
	}

}
