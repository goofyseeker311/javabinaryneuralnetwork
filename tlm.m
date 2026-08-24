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
    bwords(n,m+1) = cast(byteword(1,m),"int64") + 255*(m-1);
  endfor
endfor

bwordsm = size(bwords,2)-1;
bwordsm2 = bwordsm * 255 ;

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
vinv = inv(v);

a = swordscentered(1,:);
b = linsolve(v, a');
c = v*b + swordsmean';
figure(1); plot(c,'-o');

acc = zeros(1,wordsn);

for n = 1:wordsn
  a = swordscentered(n,:);
  b = vinv * a';
  c = v*b + swordsmean';
  acc(n) = c(bwordsm2+n);
  printf("acc %i: %f\n",n,acc(n));
endfor
figure(2); plot(acc,'-o');

