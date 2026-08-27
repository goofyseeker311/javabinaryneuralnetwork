close all; clear; output_precision(16);

filename = "words.txt";
fid = fopen(filename);
words = textscan(fid, "%s");
words = words{1};
fclose (fid);

wordsn = size(words,1);
printf("words loaded (%i).\n",wordsn);

bwords = zeros(wordsn,32);
for n = 1:wordsn
  byteword = unicode2native(words{n,1}, "ISO-8859-1");
  bwordm = size(byteword,2);
  for m = 1:bwordm
    bwords(n,m) = cast(byteword(1,m),"int64") + 256*(m-1)+1;
  endfor
endfor

wordchars = nonzeros(unique(bwords));
charinds(wordchars) = 1:length(wordchars);
swordsn = size(bwords,1);
swordsm = size(bwords,2);
for n = 1:swordsn
  for m = 1:swordsm
    if (bwords(n,m)> 0)
      bwords(n,m) = charinds(bwords(n,m));
    endif
  endfor
endfor

charmax = max(max(bwords));
charsum = sum(sum(bwords>0));
printf("bwords (%i,%i).\n",swordsn,swordsm);

swords = spalloc(wordsn,charmax,charsum);
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
swordslen = size(swordsfull,2);
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

svdcomps = 30;
[u, s, v] = svds(swords,svdcomps);
vinv = v\eye(swordslen);
printf("svdinv (%i,%i).\n",size(v,1),size(v,2));

bb = vinv * swordscentered';
v2 = eye(wordsn)\bb';

acc = zeros(1,wordsn);
for n = 1:wordsn
  c = v2*bb(:,n);
  acc(n) = c(n);
  [wm,im] = max(c);
  if (n!=im)
    printf("predicted(%i): %s, actual: %s, conf: %f\n",n,words{im},words{n},acc(n));
  endif
endfor

word = "homan";
wordb = unicode2native(word, "ISO-8859-1");
wordm = size(wordb,2);
worda = zeros(1,swordslen);
for m = 1:wordm
  if (wordb(m) > 0)
    n = charinds(cast(wordb(m),"int64") + 256*(m-1)+1);
    worda(1,n) = 1;
  endif
endfor
wordcentered = worda - swordsmean;
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

