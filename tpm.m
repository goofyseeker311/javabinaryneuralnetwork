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
function floatvalue = halftofloat(halfvalue)
  longvalue = cast(halfvalue,'int64');
  longsign = bitshift(bitand(longvalue,cast(0x8000,'int64')),-15);
  longexp = bitshift(bitand(longvalue,cast(0x7C00,'int64')),-10) - 15 + 127;
  longfrac = bitand(longvalue,cast(0x3FF,'int64'));
  if (longexp == 112) longexp = cast(0x0,'int64');
  elseif (longexp == 143) longexp = cast(0xFF,'int64'); endif
  longfloat = bitor(bitor( (bitshift(longsign,31)) , (bitshift(longexp,23)) ) , (bitshift(longfrac,13)) );
  bitfloat = bitunpack(longfloat);
  floatvalue = bitpack(bitfloat(:,1:32),'single');
endfunction
function halfvalue = floattohalf(floatvalue)
  longvalue = cast(typecast(cast(floatvalue,'single'),'int32'),'int64');
  longsign = bitshift(bitand(longvalue,cast(0x80000000,'int64')),-31);
  longexp = bitshift(bitand(longvalue,cast(0x7F800000,'int64')),-23) - 127 + 15;
  longfrac = bitshift(bitand(longvalue,cast(0x7FFFFF,'int64')),-13);
  if (longexp == -112) longexp = cast(0,'int64');
  elseif (longexp == 143) longexp = cast(0x1F,'int64');
  elseif (longexp <= 0) longexp = cast(0,'int64'); longfrac = cast(0,'int64');
  elseif (longexp >= 31) longexp = cast(0x1F,'int64'); longfrac = cast(0,'int64');
  else
    roundup = bitand(longvalue,cast(0x1000,'int64'));
    if (roundup!=0)
      if (longfrac==0x3FF)
        longexp += 1;
      endif
      longfrac += 1;
      longfrac = bitand(longfrac,cast(0x3FF,'int64'));
    endif
  endif
  floatvalue = bitor(bitor( (bitshift(longsign,15)) , (bitshift(longexp,10))) , longfrac);
  bitvalue = bitunpack(floatvalue);
  halfvalue = bitpack(bitvalue(:,1:16),'int16');
endfunction

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
sc = 65536 / max(abs([min(bb(:)) max(bb(:))]));
bb *= sc;
bbq = zeros(size(bb),'int16');
for n = 1:size(bb,1)
  for m = 1:size(bb,2)
    bbq(n,m) = floattohalf(bb(n,m));
  endfor
endfor
bb = bbq;
save -binary -zip image.mat bb sc;

clear bb sc;
load image.mat;
bbq = zeros(size(bb),'single');
for n = 1:size(bb,1)
  for m = 1:size(bb,2)
    bbq(n,m) = halftofloat(bb(n,m));
  endfor
endfor
bb = cast(bbq,'double') / sc;

aa = (vv * bb)' + swordsmean;
cc = svdcomps / swordslen;
ad = data - aa;
adf = isfinite(ad(:));
dd = mean(abs(ad(adf)));
dds = std(ad(adf));

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

