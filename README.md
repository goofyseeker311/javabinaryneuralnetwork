# Java Binary Neural Network

* Binary neural network with 0/1 invert weights.
* Trained with evolutionary reinforcement algorithm, at various cycle counts.
* Swapped memory array is filled with data at inputs and zeros otherwise.
* Output data is OR with any duplicate output data.
* Using int32 storage for memory and weight bits computes 32x input data or weight variations.

Neural OR/NOR node compute [bit1,bit2] -> bit:

Output = (Input1 OR Input2) XOR Weight
