close all; clear; output_precision(16);

img = imread("image.jpg");

tiledim = 16;
tilesize = tiledim^2;
tilergb = tilesize*3;
tilex = ceil(size(img,2)/tiledim);
tiley = ceil(size(img,1)/tiledim);
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

svdcomps = 100;
[u, s, v] = svd(swordsfull);
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';
printf("svdinv (%i,%i).\n",size(vv,2),size(vv,1));

bb = vinv * swordscentered';
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
img2 = cast(img2, "uint8");

figure(1); image(img);
figure(2); image(img2);
printf("compression ratio: %i/%i=%f, average/std error: %f+%f\n",svdcomps,swordslen,cc,dd,dds);

