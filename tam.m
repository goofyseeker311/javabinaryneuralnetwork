close all; clear; output_precision(16);

[img,fs] = audioread("audio.mp3");

tiledim = 16*16;
tilex = 2;
tiley = ceil(size(img,1)/tiledim);
tilesize = tiledim * tilex;
data = zeros(tiley,tilesize);

img(tiley*tiledim,:) = [0,0];
for n = 1:tiley
  tile = img((n-1)*tiledim+(1:tiledim),:);
  data(n,:) = reshape(tile,1,tilesize);
endfor

wordsn = size(data,1);
words = data;
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = mean(swordsfull,1);
swordscentered = swordsfull - swordsmean;
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

svdcomps = 67;
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

img2 = zeros(tiley*tiledim,2);
for n = 1:tiley
  tile = reshape(data(n,:),tiledim,2);
  img2((n-1)*tiledim+(1:tiledim),:) = tile;
endfor

sound(img,fs);
sound(img2,fs);
printf("compression ratio: %i/%i=%f, average/std error: %f+%f\n",svdcomps,swordslen,cc,dd,dds);

