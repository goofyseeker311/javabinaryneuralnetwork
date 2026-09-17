close all; clear; output_precision(16);

load images.mat;

wordsn = size(data,1);
words = data; clear data;
printf("words loaded (%i).\n",wordsn);

tiledim = 32;
tilesize = tiledim^2;
tilergb = tilesize*3;

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsfull1 = swordsfull(:,0*tilesize+(1:tilesize));
swordsfull2 = swordsfull(:,1*tilesize+(1:tilesize));
swordsfull3 = swordsfull(:,2*tilesize+(1:tilesize));
swordsmean1 = mean(swordsfull1,2);
swordsmean2 = mean(swordsfull2,2);
swordsmean3 = mean(swordsfull3,2);
swordsmean = [swordsmean1 swordsmean2 swordsmean3];
swordscentered1 = swordsfull1 - swordsmean1;
swordscentered2 = swordsfull2 - swordsmean2;
swordscentered3 = swordsfull3 - swordsmean3;
swordscentered = [swordscentered1 swordscentered2 swordscentered3];
printf("swords (%i,%i).\n",size(swordsfull,1),swordslen);

[u, s, v] = svd(swordsfull,'econ');
vinv = (eye(swordslen)/v')';
printf("svdinv (%i,%i).\n",size(v,1),size(v,2));

aa = zeros(wordsn,10);
for n = 1:wordsn
  aa(n,labels(n)+1) = 1;
endfor

bb = vinv * swordscentered';
cc = (v * bb)';
cc1 = cc(:,0*tilesize+(1:tilesize)) + swordsmean(:,1);
cc2 = cc(:,1*tilesize+(1:tilesize)) + swordsmean(:,2);
cc3 = cc(:,2*tilesize+(1:tilesize)) + swordsmean(:,3);
cc = [cc1 cc2 cc3];
v2 = aa\bb';
v3 = v2 * vinv;

acc = zeros(1,wordsn);
accc = 0;
for n = 1:wordsn
  c = v2*bb(:,n);
  labelsn = labels(n);
  acc(n) = c(labelsn+1);
  [wm,im] = max(c);
  labelsc = im-1;
  if (labelsn==labelsc)
    accc = accc + 1;
  else
    printf("predicted(%i): '%i', actual: %i, conf: %f\n",n,labelsc,labelsn,acc(n));
  endif
endfor
cacc = accc/wordsn;
printf("training accuracy: %f\n",cacc);

labels2 = labels;
load imagest.mat;
wordsn = size(data,1);
words = cast(data,"double"); clear data;

swordsfull = cast(words,"double");
swordslen = size(swordsfull,2);
swordsfull1 = swordsfull(:,0*tilesize+(1:tilesize));
swordsfull2 = swordsfull(:,1*tilesize+(1:tilesize));
swordsfull3 = swordsfull(:,2*tilesize+(1:tilesize));
swordsmean1 = mean(swordsfull1,2);
swordsmean2 = mean(swordsfull2,2);
swordsmean3 = mean(swordsfull3,2);
swordsmean = [swordsmean1 swordsmean2 swordsmean3];
swordscentered1 = swordsfull1 - swordsmean1;
swordscentered2 = swordsfull2 - swordsmean2;
swordscentered3 = swordsfull3 - swordsmean3;
swordscentered = [swordscentered1 swordscentered2 swordscentered3];

acc = zeros(1,wordsn);
accc = 0;
for n = 1:wordsn
  c = v3 * swordscentered(n,:)';
  labelsn = labels(n);
  acc(n) = c(labelsn+1);
  [wm,im] = max(c);
  labelsc = im-1;
  if (labelsn==labelsc)
    accc = accc + 1;
  else
    printf("predicted(%i): '%i', actual: %i, conf: %f\n",n,labelsc,labelsn,acc(n));
  endif
endfor
cacc2 = accc/wordsn;
printf("testing accuracy: %f\n",cacc2);

word = 28;
wordl = labels(word)+1;
wordc = v3 * swordscentered(word,:)';
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
printf("1. predicted(%i): '%i', a: '%i', conf: %f\n",im1,labels2(im1),labels(wordl),wm1);
printf("2. predicted(%i): '%i', a: '%i', conf: %f\n",im2,labels2(im2),labels(wordl),wm2);
printf("3. predicted(%i): '%i', a: '%i', conf: %f\n",im3,labels2(im3),labels(wordl),wm3);
printf("4. predicted(%i): '%i', a: '%i', conf: %f\n",im4,labels2(im4),labels(wordl),wm4);
printf("5. predicted(%i): '%i', a: '%i', conf: %f\n",im5,labels2(im5),labels(wordl),wm5);
printf("6. predicted(%i): '%i', a: '%i', conf: %f\n",im6,labels2(im6),labels(wordl),wm6);

