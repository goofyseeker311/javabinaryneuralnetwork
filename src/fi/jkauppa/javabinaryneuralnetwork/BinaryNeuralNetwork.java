package fi.jkauppa.javabinaryneuralnetwork;

public class BinaryNeuralNetwork {
	
	public BinaryNeuralNetwork() {
	}

	public static class Network {
		private int[] memory = null;
		private int layerind = 0;
		private int layerlen = 0;
		private Node[] layers = null;
		
		public Network(int vmemorysize, int vlayerind, int vlayerlen, int vlayersize) {
			memory = new int[vmemorysize];
			layerind = vlayerind;
			layerlen = vlayerlen;
			layers = new Node[vlayersize];
		}
	}
	
	public static class Node {
		public int input1ind = 0;
		public int input2ind = 0;
		public int xorweight = 0;
		public int outputind = 0;
	}

}
