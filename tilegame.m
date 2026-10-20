close all; clear; output_precision(16);

function vecdir = vectordirection(x)
  vecdir = acos(dot([0 1]'*ones(1,size(x,2)),x./vecnorm(x)));
  vecdir(sign(x(1,:))<0) *= -1;
endfunction

a = [
  [0 1 2 3 4 5 6 7 8] [1 2 3 4 5 6 8] [1 2 4 5 7 8] [1 2 3 4 6 7 8] [5 6 7 8] [5 7 8] [5 6 7 8] [5 6 7 8] 8;
  [8 8 8 8 8 8 8 8 8] [7 7 7 7 7 7 7] [6 6 6 6 6 6] [5 5 5 5 5 5 5] [4 4 4 4] [3 3 3] [2 2 2 2] [1 1 1 1] 0
]/8;
a = [flip([-a(1,:);a(2,:)],2) a];
a = [a flip([a(1,:);-a(2,:)],2)];
a = unique(a',"rows")';
b = vectordirection(a);
c = sort(b);
d = round(a*2^3);
figure(1); plot(c,'o-'); xlim([1 176]); ylim([-pi pi]);
figure(2); scatter(a(1,:),a(2,:));

fn = "tiledata.prg";
fopen(fn,'w');
fwrite(fn,cast(0x6000,'uint16'),'uint16',0,'l');
fwrite(fn,cast(d','int8'),'int8',0,'l');
fclose(fn);

fov = 70 * pi/180;
len = atan(fov);
drs = 32;
stp = 40;
a2 = len*(-1:2/(stp-1):1);
b2 = [a2;ones(size(a2))];
b3 = vectordirection(b2);
[b3a,b3i] = min(abs(b3 - b'));
b4a = a(:,b3i);
figure(3); scatter(b4a(1,:),b4a(2,:));
b2a = [];
for n = 1:drs
  rz = rotz((n-1)/drs*360);
  rz = rz(1:2,1:2);
  rd = rz*b2;
  rd2 = vectordirection(rd);
  [rd3,rd3i] = min(abs(rd2 - b'));
  rd3 = a(:,rd3i);
  figure(n+3); scatter(rd3(1,:),rd3(2,:)); xlim([-1 1]); ylim([-1 1]);
  rda = [];
  rda(1:2:size(rd3,2)*2) = rd3(1,:);
  rda(2:2:size(rd3,2)*2) = rd3(2,:);
  b2a = [b2a; rda];
endfor
c2 = round(b2a*2^3);

fn = "tiledata2.prg";
fopen(fn,'w');
fwrite(fn,cast(0x6000,'uint16'),'uint16',0,'l');
fwrite(fn,cast(c2','int8'),'int8',0,'l');
fclose(fn);

tileddim = 16;
tiledsize = 256;
tiledroom = [
	1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 1, 1, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	1, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
];
tiledroom = randi(4,tileddim,tileddim)-3;
tiledroom(tiledroom<0) = 0;

fn = "tiledroom.prg";
fopen(fn,'w');
fwrite(fn,cast(0x4000,'uint16'),'uint16',0,'l');
fwrite(fn,cast(tiledroom','uint8'),'uint8',0,'l');
fclose(fn);

tiledsdf = inf(tileddim,tileddim);
for j = 1:tileddim
  for i = 1:tileddim
    for l = 1:tileddim
      for k = 1:tileddim
        if (tiledroom(l,k)>0)
          md = sqrt((j-l)^2+(i-k)^2);
          if (md < tiledsdf(j,i))
            tiledsdf(j,i) = md;
          endif
        endif
      endfor
    endfor
  endfor
endfor
tiledsdf = floor(log2(tiledsdf));
tiledsdf(tiledsdf<0) = 0;
tiledsdf(tiledsdf>4) = 4;

fn = "tiledsdf.prg";
fopen(fn,'w');
fwrite(fn,cast(0x5000,'uint16'),'uint16',0,'l');
fwrite(fn,cast(tiledsdf','uint8'),'uint8',0,'l');
fclose(fn);

