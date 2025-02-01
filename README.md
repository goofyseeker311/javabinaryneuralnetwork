# Java Binary Neural Network

Binary neural network with 0/1 invert weights and 0/1 node masks.
Trained with evolutionary reinforcement gradient descent algorithm.

Neural node compute int64 -> bit:

Output = OR (Input AND Mask XOR Invert)
