close all; clear; output_precision(16);

function intval = fptoint8(fpval)
  intval = log(abs(fpval))*13.19035+64;
  intval(intval<0) = 0;
  intval = intval.*sign(fpval);
endfunction

function fpval = int8tofp(intval)
  fpval = sign(intval).*exp((abs(intval)-64)/13.19035);
endfunction

img = imread("image.jpg");

tiledim = 16;
tilesize = tiledim^2;
tilergb = tilesize*3;
imgx = size(img,2);
imgy = size(img,1);
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
data = zeros(tilex*tiley,tilergb);

img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
for n = 1:tiley
  for m = 1:tilex
    tile = img((n-1)*tiledim+(1:16),(m-1)*tiledim+(1:16),:);
    data((n-1)*tilex+m,:) = reshape(tile,1,tilergb);
  endfor
endfor

wordsn = size(data,1);
words = data;
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = mean(swordsfull,1);
swordscentered = swordsfull - swordsmean;
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

svdcomps = swordslen;
[u, s, v] = svd(swordsfull,'econ');
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';
vinvfn = "tpm.bin";
fopen(vinvfn,'w');
fwrite(vinvfn,cast(vinv,'single')','single',0,'b');
fclose(vinvfn);
fopen(vinvfn);
vinvb = cast(fread(vinvfn,[svdcomps Inf],'int8',0,'b'),'int8');
fclose(vinvfn);
printf("svdinv (%i,%i).\n",size(vv,2),size(vv,1));

bb = vinv * swordscentered';
sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
if (isinf(sc)) sc = 1; endif
bb = cast(fptoint8(bb * sc),'int8');
save -binary -zip image.mat bb sc swordsmean swordslen svdcomps tilex tiley tiledim imgx imgy;

clear bb sc;
load image.mat;
bb = int8tofp(cast(bb,'double')) / sc;

aa = (vv * bb)' + swordsmean;
cc = svdcomps / swordslen;
ad = data - aa;
dd = mean(abs(ad(:)));
dds = std(ad(:));

img2 = zeros(tiley*tiledim,tilex*tiledim,3);
for n = 1:tiley
  for m = 1:tilex
    tile = aa((n-1)*tilex+m,:);
    img2((n-1)*tiledim+(1:16),(m-1)*tiledim+(1:16),:) = reshape(tile,tiledim,tiledim,3);
  endfor
endfor
img2(img2(:)<0) = 0;
img2(img2(:)>255) = 255;
img2 = cast(img2, "uint8");

img = img(1:imgy,1:imgx,:);
img2 = img2(1:imgy,1:imgx,:);

figure(1); image(img); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;
figure(2); image(img2); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;
printf("compression ratio: %i/%i=%f, average/std error: %f+%f\n",svdcomps,swordslen,cc,dd,dds);

