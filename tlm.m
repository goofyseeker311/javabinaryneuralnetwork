close all; clear; output_precision(16);

filename = "words.txt";
fid = fopen(filename);
words = textscan(fid, "%s");
words = words{1};
fclose (fid);

wordsn = size(words,1);
bwords = cast(0,"int64");

for n = 1:wordsn
  byteword = unicode2native(words{n,1}, "ISO-8859-1");
  bwordm = size(byteword,2);

  for m = 1:bwordm
    bwords(n,m+1) = cast(byteword(1,m),"int64") + (256*(m-1)-1);
  endfor
endfor

bwordsm = size(bwords,2)-1;
bwordsm2 = bwordsm * 256 - 1;

for n = 1:wordsn
  wordsnind = bwordsm2 + n;
  words(n,2) = wordsnind;
  bwords(n,1) = wordsnind;
endfor

swords = spalloc(wordsn, wordsnind, wordsnind);
swordsn = size(bwords,1);
swordsm = size(bwords,2);

for n = 1:swordsn
  for m = 1:swordsm
    bwordsind = bwords(n,m);
    if (bwordsind > 0)
      swords(n,bwordsind) = 1;
    endif
  endfor
endfor

swordsfull = full(swords);
swordsmean = mean(swordsfull,1);
swordscentered = swordsfull - swordsmean;
[u, s, v] = svd(swordscentered);

ir = 1:bwordsm2;
vinv = inv(v(ir,ir));

a = swordscentered(1,:);
b = vinv * a(ir)';
c = v(:,ir)*b + swordsmean';
figure(1); plot(c,'-o');

acc = zeros(1,wordsn);

for n = 1:wordsn
  a = swordscentered(n,:);
  b = vinv * a(ir)';
  c = v(:,ir)*b + swordsmean';
  acc(n) = c(bwordsm2+n);
endfor
figure(2); plot(acc,'-o');

