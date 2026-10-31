close all; clear; output_precision(16);

function treeout = createbinarytreenode(binarytree, address, value)
  tree = binarytree;
  if (isempty(tree))
    tree = containers.Map();
  endif
  addresslength = size(address,2);
  for i = 0:addresslength
    leafkey = "";
    if (addresslength>0)
      leafkey = address(1,1:i);
    endif
    printf("-%s",leafkey);
    leafvalue = [];
    if (tree.isKey(leafkey))
      leafvalue = tree(leafkey);
    else
      leafvalue = [];
      tree(leafkey) = leafvalue;
    endif
    if (i==addresslength)
      leafvalue = value;
      tree(leafkey) = leafvalue;
    endif
    printf(": '%d'", leafvalue);
    printf("\n");
  endfor
  treeout = tree;
endfunction

function valueout = readbinarytreenode(binarytree, address)
  tree = binarytree;
  if (isempty(tree))
    valueout = [];
    return;
  endif
  leafvalue = [];
  if (tree.isKey(address))
    leafvalue = tree(address);
  endif
  printf("-%s: '%d'", address, leafvalue);
  printf("\n");
  valueout = leafvalue;
endfunction

binarytree = [];
binarytree = createbinarytreenode(binarytree, "010", 15);
binarytree = createbinarytreenode(binarytree, "", 0);
binarytree = createbinarytreenode(binarytree, "1111", 22);
binarytree = createbinarytreenode(binarytree, "010", 33);
valueout1 = readbinarytreenode(binarytree, "");
valueout2 = readbinarytreenode(binarytree, "010");
valueout3 = readbinarytreenode(binarytree, "1111");

