close all; clear; output_precision(16);

[img,fs] = audioread("audio.mp3");

tiledim = 128;
tilex = 2;
tiley = ceil(size(img,1)/tiledim);
tilesize = tiledim * tilex;
data = zeros(tiley,tilesize);

img(tiley*tiledim,:) = [0,0];
for n = 1:tiley
  tile = img((n-1)*tiledim+(1:tiledim),:);
  data(n,:) = reshape(tile,1,tilesize);
endfor

words = data;
wordsn = size(data,1);
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = mean(swordsfull,1);
swordscentered = swordsfull - swordsmean;
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

svdcomps = 60;
[u, s, v] = svd(swordsfull(1:32000,:));
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';
printf("svdinv (%i,%i).\n",size(vv,2),size(vv,1));

bb = vinv * swordscentered';
sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
bb = cast(bb * sc, 'int8');
save -binary audio.mat bb sc;

clear bb sc;
load audio.mat;
bb = cast(bb, 'double') / sc;

aa = (vv * bb)' + swordsmean;
cc = svdcomps / swordslen;
ad = data - aa;
dd = mean(abs(ad(:)));
dds = std(ad(:));

img2 = zeros(tiley*tiledim,2);
for n = 1:tiley
  tile = reshape(aa(n,:),tiledim,2);
  img2((n-1)*tiledim+(1:tiledim),:) = tile;
endfor

sound(img,fs);
sound(img2,fs);
printf("compression ratio: %i/%i=%f, average/std error: %f+%f\n",svdcomps,swordslen,cc,dd,dds);

ssm = 50000:200000;
ws = 384; ws2 = ws/2;
spi = img2(ssm,:);
ss = ceil(size(ssm,2)/ws)-1;
spc = zeros(ss,ws);
for n = 1:ss
  spc(n,:) = fft(spi((n-1)*ws+(1:ws),1),ws);
endfor
spg = log10(abs(spc(:,1:ws2)))';
surf(spg,'facelighting','none','edgecolor','none'); view(2); axis tight;
colormap(jet); clim([-1 2]);
xtick = [0.5 1 1.5 2 2.5 3];
ytick = [0 0.5 1 1.5 2];
xticks(xtick*(fs/ws));
xticklabels(xtick);
yticks(ytick*ws/4);
yticklabels(ytick*fs/4);

