close all; clear; output_precision(16);

function floatvalue = minitofloat(minivalue)
  longvalue = cast(minivalue,'int64');
  longsign = bitshift(bitand(longvalue,cast(0x80,'int64')),-7);
  longexp = bitshift(bitand(longvalue,cast(0x78,'int64')),-3) - 7 + 127;
  longfrac = bitand(longvalue,cast(0x7,'int64'));
  if (longexp == 120) longexp = cast(0x0,'int64');
  elseif (longexp == 135) longexp = cast(0xFF,'int64'); endif
  longfloat = bitor(bitor( (bitshift(longsign,31)) , (bitshift(longexp,23)) ) , (bitshift(longfrac,20)) );
  bitfloat = bitunpack(longfloat);
  floatvalue = bitpack(bitfloat(:,1:32),'single');
endfunction
function minivalue = floattomini(floatvalue)
  longvalue = cast(typecast(cast(floatvalue,'single'),'int32'),'int64');
  longsign = bitshift(bitand(longvalue,cast(0x80000000,'int64')),-31);
  longexp = bitshift(bitand(longvalue,cast(0x7F800000,'int64')),-23) - 127 + 7;
  longfrac = bitshift(bitand(longvalue,cast(0x7FFFFF,'int64')),-20);
  if (longexp == -120) longexp = cast(0,'int64');
  elseif (longexp == 135) longexp = cast(0xF,'int64');
  elseif (longexp <= 0) longexp = cast(0,'int64'); longfrac = cast(0,'int64');
  elseif (longexp >= 15) longexp = cast(0xF,'int64'); longfrac = cast(0,'int64');
  else
    roundup = bitand(longvalue,cast(0x80000,'int64'));
    if (roundup!=0)
      if (longfrac==0x7)
        longexp += 1;
      endif
      longfrac += 1;
      longfrac = bitand(longfrac,cast(0x7,'int64'));
    endif
  endif
  floatvalue = bitor(bitor( (bitshift(longsign,7)) , (bitshift(longexp,3))) , longfrac);
  bitvalue = bitunpack(floatvalue);
  minivalue = bitpack(bitvalue(:,1:8),'int8');
endfunction

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
sc = 256 / max(abs([min(bb(:)) max(bb(:))]));
bb *= sc;
bbq = zeros(size(bb),'uint8');
for n = 1:size(bb,1)
  for m = 1:size(bb,2)
    bbq(n,m) = floattomini(bb(n,m));
  endfor
endfor
bb = bbq;
save -binary -zip audio.mat bb sc;

clear bb sc;
load audio.mat;
bbq = zeros(size(bb),'single');
for n = 1:size(bb,1)
  for m = 1:size(bb,2)
    bbq(n,m) = minitofloat(bb(n,m));
  endfor
endfor
bb = cast(bbq,'double') / sc;

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

