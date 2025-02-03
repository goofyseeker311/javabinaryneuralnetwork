package fi.jkauppa.javabinaryneuralnetwork;

public class BinaryNeuralNetwork {
	
	public BinaryNeuralNetwork() {
	}

	public static class Network {
		Node[] inputlayer = null;
		Node[] hiddenlayers = null;
		Node[] outputlayer = null;
	}
	
	public static class Node {
		public long data = 0;
		public long weight = 0;
		public Node out = null;
		public byte bitind = 0;
	}

}
