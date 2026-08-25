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
ir = 1:bwordsm2;

[u, s, v] = svd(swordscentered(:,ir));
vinv = inv(v);

bb = vinv * swordscentered(:,ir)';
v2 = (bb'\eye(wordsn))';
cc = v2*bb;
[cwm,cim] = max(cc,[],1);
acc = diag(cc);

for n = 1:wordsn
  if (n!=cim(n))
    printf("predicted(%i): %s, actual: %s, conf: %f\n",n,words{cim(n)},words{n},acc(n));
  endif
endfor
figure(1); plot(acc,'-o');

word = "homan";
wordb = unicode2native(word, "ISO-8859-1");
wordm = size(wordb,2);
worda = zeros(1,bwordsm2);
for m = 1:wordm
  n = (256*(m-1)-1) + cast(wordb(m),"int64");
  if (wordb(m) > 0)
    worda(1,n) = 1;
  endif
endfor
wordcentered = worda - swordsmean(ir);
wordb = vinv * wordcentered';
wordc = v2 * wordb;
[ws,is] = sort(wordc);
wm1 = ws(wordsn);
wm2 = ws(wordsn-1);
wm3 = ws(wordsn-2);
wm4 = ws(wordsn-3);
wm5 = ws(wordsn-4);
wm6 = ws(wordsn-5);
im1 = is(wordsn);
im2 = is(wordsn-1);
im3 = is(wordsn-2);
im4 = is(wordsn-3);
im5 = is(wordsn-4);
im6 = is(wordsn-5);
printf("1. predicted(%i): %s, actual: %s, conf: %f\n",im1,words{im1},word,wm1);
printf("2. predicted(%i): %s, actual: %s, conf: %f\n",im2,words{im2},word,wm2);
printf("3. predicted(%i): %s, actual: %s, conf: %f\n",im3,words{im3},word,wm3);
printf("4. predicted(%i): %s, actual: %s, conf: %f\n",im4,words{im4},word,wm4);
printf("5. predicted(%i): %s, actual: %s, conf: %f\n",im5,words{im5},word,wm5);
printf("6. predicted(%i): %s, actual: %s, conf: %f\n",im6,words{im6},word,wm6);

