close all; clear; output_precision(16);

img = imread("image.jpg");

c64colors = [
  0x00 0x00 0x00
  0xff 0xff 0xff
  0x88 0x00 0x00
  0xAA 0xFF 0xEE
  0xCC 0x44 0xCC
  0x00 0xCC 0x55
  0x00 0x00 0xAA
  0xEE 0xEE 0x77
  0xDD 0x88 0x55
  0x66 0x44 0x00
  0xFF 0x77 0x77
  0x33 0x33 0x33
  0x77 0x77 0x77
  0xAA 0xFF 0x66
  0x00 0x88 0xFF
  0xBB 0xBB 0xBB
];
c64rgb = cast(c64colors,'double');
c64map = c64rgb/255;

tiledim = 8;
tilesize = tiledim^2;
tilergb = tilesize*3;
imgx = size(img,2);
imgy = size(img,1);
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
data = zeros(tilex*tiley,tilesize);

tileunique = 0;
img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
for n = 1:tiley
  for m = 1:tilex
    tile = img((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:);
    tiledither = dither(tile,c64map,1,1);
    tileunique += size(tileunique,1)>2;
    data((n-1)*tilex+m,:) = reshape(tiledither,1,tilesize);
  endfor
endfor

wordsn = size(data,1);
words = data;
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = mean(swordsfull,2);
swordscentered = swordsfull - swordsmean;
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

svdcomps = swordslen;
[u, s, v] = svd(swordsfull,'econ');
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';
printf("svdinv (%i,%i).\n",size(vv,2),size(vv,1));

bb = vinv * swordscentered';
sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
if (isinf(sc)) sc = 1; endif
bb = cast(bb * sc,'int8');
swordsmean = cast(swordsmean,'uint8');
save -binary -zip image.mat bb sc swordsmean swordslen svdcomps tilex tiley tiledim imgx imgy;

clear bb sc;
load image.mat;
swordsmean = cast(swordsmean,'double');
bb = cast(bb,'double') / sc;

aa = (vv * bb)' + swordsmean;
cc = svdcomps / swordslen;
ad = data - aa;
dd = mean(abs(ad(:)));
dds = std(ad(:));

img2 = zeros(tiley*tiledim,tilex*tiledim);
for n = 1:tiley
  for m = 1:tilex
    tile = aa((n-1)*tilex+m,:);
    img2((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:) = reshape(tile,tiledim,tiledim);
  endfor
endfor
img2(img2(:)<0) = 0;
img2(img2(:)>15) = 15;
img2 = cast(img2, "uint8");

img = img(1:imgy,1:imgx,:);
img2 = img2(1:imgy,1:imgx,:);

figure(1); image(img); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;
figure(2); image(img2); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;
printf("compression ratio: %i/%i=%f, average/std error: %f+%f\n",svdcomps,swordslen,cc,dd,dds);

