close all; clear; output_precision(16);

load images.mat;
#data = data(1:2000,:);

wordsn = size(data,1);
words = data; clear data;
printf("words loaded (%i).\n",wordsn);

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsmean = mean(swordsfull,1);
swordscentered = swordsfull - swordsmean;
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

[u, s, v] = svd(swordsfull);
vinv = (eye(swordslen)/v')';
printf("svdinv (%i,%i).\n",size(v,1),size(v,2));

#aa = eye(wordsn);
aa = zeros(wordsn,10);
for n = 1:wordsn
  aa(n,labels(n)+1) = 1;
endfor

bb = vinv * swordscentered';
cc = (v * bb)' + swordsmean;
v2 = aa\bb';
v3 = v2 * vinv;

acc = zeros(1,wordsn);
accc = 0;
for n = 1:wordsn
  c = v2*bb(:,n);
  labelsn = labels(n)+1;
  acc(n) = c(labelsn);
  [wm,im] = max(c);
  if (labelsn==im)
    accc = accc + 1;
  else
    printf("predicted(%i): '%i', actual: %i, conf: %f\n",n,im,labelsn,acc(n));
  endif
endfor
cacc = accc/wordsn;
printf("accuracy: %f\n",cacc);

load imagest.mat;
wordsn = size(data,1);
words = cast(data,"double"); clear data;

acc = zeros(1,wordsn);
accc = 0;
for n = 1:wordsn
  c = v3 * (words(n,:) - swordsmean)';
  labelsn = labels(n)+1;
  acc(n) = c(labelsn);
  [wm,im] = max(c);
  if (labelsn==im)
    accc = accc + 1;
  else
    printf("predicted(%i): '%i', actual: %i, conf: %f\n",n,im,labelsn,acc(n));
  endif
endfor
cacc = accc/wordsn;
printf("accuracy: %f\n",cacc);

word = 11;
wordl = labels(word);
wordb = words(word,:);
worda = cast(wordb,"double");
wordc = v3 * (worda - swordsmean)';
[ws,is] = sort(wordc);
wm1 = ws(end);
wm2 = ws(end-1);
wm3 = ws(end-2);
wm4 = ws(end-3);
wm5 = ws(end-4);
wm6 = ws(end-5);
im1 = is(end);
im2 = is(end-1);
im3 = is(end-2);
im4 = is(end-3);
im5 = is(end-4);
im6 = is(end-5);
printf("1. predicted(%i): '%i', a: '%i', conf: %f\n",word,im1,wordl,wm1);
printf("2. predicted(%i): '%i', a: '%i', conf: %f\n",word,im2,wordl,wm2);
printf("3. predicted(%i): '%i', a: '%i', conf: %f\n",word,im3,wordl,wm3);
printf("4. predicted(%i): '%i', a: '%i', conf: %f\n",word,im4,wordl,wm4);
printf("5. predicted(%i): '%i', a: '%i', conf: %f\n",word,im5,wordl,wm5);
printf("6. predicted(%i): '%i', a: '%i', conf: %f\n",word,im6,wordl,wm6);

