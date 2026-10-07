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
c64n = size(c64colors,1);

tiledim = 8;
tilesize = tiledim^2;
tilergb = tilesize*3;
imgx = size(img,2);
imgy = size(img,1);
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
data = zeros(tilex*tiley,tilesize);
colors = zeros(tilex*tiley,2);

img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
for n = 1:tiley
  for m = 1:tilex
    tile = img((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:);
    tilepixel = cast(reshape(tile,tilesize,3),'double');
    tiledither = dither(tile,c64map);
    tilesum = sum(tiledither(:)==0:c64n-1);
    [tilesort,tilesorti] = sort(tilesum);
    tilecolorsi = tilesorti(flip(1:c64n));
    color1diff = tilepixel-c64rgb(tilecolorsi(1),:);
    color1diffd = dot(color1diff,color1diff,2);
    color2diff = tilepixel-c64rgb(tilecolorsi(2),:);
    color2diffd = dot(color2diff,color2diff,2);
    colorchoice = tilecolorsi(1)*ones(tilesize,1);
    colorchoice(color2diffd<color1diffd) = tilecolorsi(2);
    for k = tilecolorsi(3:end)
      tiledither(tiledither==(k-1)) = colorchoice(k) - 1;
    endfor
    tilei1 = tiledither==(tilecolorsi(1)-1);
    tilei2 = tiledither==(tilecolorsi(2)-1);
    tiledither(tilei1) = 0;
    tiledither(tilei2) = 1;
    colors((n-1)*tilex+m,:) = tilecolorsi([1 2])-1;
    data((n-1)*tilex+m,:) = reshape(tiledither,1,tilesize);
  endfor
endfor

wordsn = size(data,1);
words = data;
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = 0.5;
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
save -binary -zip image.mat bb sc swordsmean colors swordslen svdcomps tilex tiley tiledim imgx imgy;

clear bb sc;
load image.mat;
bb = cast(bb,'double') / sc;

aa = (vv * bb)' + swordsmean;
cc = svdcomps / swordslen;
ad = data - aa;
dd = mean(abs(ad(:)));
dds = std(ad(:));
aa = cast(aa,'uint8');

img2 = zeros(tiley*tiledim,tilex*tiledim);
for n = 1:tiley
  for m = 1:tilex
    tile = aa((n-1)*tilex+m,:);
    tilei1 = tile==0;
    tilei2 = tile==1;
    tile(tilei1) = colors((n-1)*tilex+m,1);
    tile(tilei2) = colors((n-1)*tilex+m,2);
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

