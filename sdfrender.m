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
    if (i==addresslength)
      tree(leafkey) = value;
    elseif (!tree.isKey(leafkey))
      tree(leafkey) = [];
    endif
  endfor
  treeout = tree;
endfunction

function valueout = readbinarytreenode(binarytree, address)
  tree = binarytree;
  leafvalue = [];
  if (!isempty(tree))
    if (tree.isKey(address))
      leafvalue = tree(address);
    endif
  endif
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

stpx = 1920;
stpy = 1080;
asp = stpx/stpy;
fovx = 70 * pi/180;
fovy = fovx/asp;
lenx = atan(fovx);
leny = atan(fovy);
ax = lenx*(-1:(2/(stpx-1)):1);
ay = leny*(-1:(2/(stpy-1)):1);

objaabb = [-1 1; -1 1; 2 4];
sdfimage = zeros(stpy,stpx,3);

pos = zeros(stpy,stpx,3);
ray = zeros(stpy,stpx,3);
found = false(stpy,stpx,1);
hit = false(stpy,stpx,1);

mult = 1/2;
for n = 1:stpy
  ray(n,:,1) = ax.*mult;
endfor
for n = 1:stpx
  ray(:,n,2) = ay.*mult;
endfor
ray(:,:,3) = 1.*mult;

c = 0;
while ((!all(found(:)))&&(++c<10))
  hit = hit | ((pos(:,:,1)>objaabb(1,1)) & (pos(:,:,1)<objaabb(1,2)) & (pos(:,:,2)>objaabb(2,1)) & (pos(:,:,2)<objaabb(2,2)) & (pos(:,:,3)>objaabb(3,1)) & (pos(:,:,3)<objaabb(3,2)));
  pos += ray;
endwhile
sdfimage(:,:,1) = hit;
sdfimage(:,:,2) = hit;
sdfimage(:,:,3) = hit;

figure(1); image(sdfimage); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;

