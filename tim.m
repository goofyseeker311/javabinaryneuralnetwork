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

bb = vinv * swordscentered';
v2 = eye(wordsn)\bb';
v3 = v2 * vinv;

acc = zeros(1,wordsn);
accs = 0;
for n = 1:wordsn
  c = v2*bb(:,n);
  acc(n) = c(n);
  [wm,im] = max(c);
  if (n!=im)
    printf("predicted(%i): '%i', conf: %f\n",n,im,acc(n));
    accs = accs + 1;
  endif
endfor
tacc = (wordsn-accs)/wordsn;
printf("accuracy: %f\n",tacc);

#load imagest.mat;
#words = data; clear data;

word = 1;
wordl = labels(word);
wordb = words(word,:);
worda = cast(wordb,"double");
wordc = v3 * (worda - swordsmean)';
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
printf("1. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im1,word,labels(im1),wordl,wm1);
printf("2. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im2,word,labels(im2),wordl,wm2);
printf("3. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im3,word,labels(im3),wordl,wm3);
printf("4. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im4,word,labels(im4),wordl,wm4);
printf("5. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im5,word,labels(im5),wordl,wm5);
printf("6. predicted(%i): '%i', c: '%i', a: '%i', conf: %f\n",im6,word,labels(im6),wordl,wm6);

