close all; clear; output_precision(16);

a = (0:1/256:1)*2*pi;
b = [sin(a);cos(a)];
c = b * .5;
d = round(c*2^8);

fn = "tiledata.prg";
fopen(fn,'w');
fwrite(fn,cast(0x5000,'uint16'),'uint16',0,'l');
fwrite(fn,cast(d,'int16'),'int16',0,'l');
fclose(fn);

scatter(d(1,:),d(2,:)); daspect([1 1])

