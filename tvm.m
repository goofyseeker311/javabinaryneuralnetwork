close all; clear; output_precision(16);

pkg load video image;

function intval = fptoint(fpval,bitn)
  bits = 2^(bitn-2);
  bitm = bits/log(2*bits);
  intval = log(abs(fpval))*bitm+bits;
  intval(intval<0) = 0;
  intval = intval.*sign(fpval);
endfunction

function fpval = inttofp(intval,bitn)
  bits = 2^(bitn-2);
  bitm = bits/log(2*bits);
  fpval = sign(intval).*exp((abs(intval)-bits)/bitm);
endfunction

filename = "video.mp4";
vid = VideoReader(filename);
vframes = vid.NumberOfFrames;
imgx = vid.Width;
imgy = vid.Height;
cframes = 8;
chunks = ceil(vframes/cframes);

tiledim = 16;
tilesize = tiledim^2;
tilergb = tilesize*3;
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
tilesmp = tilex*tiley;
swordslen = tilergb*cframes;
chunkdata = zeros(tilesmp*chunks,swordslen,'uint8');

for fc = 1:chunks
  chunkfull = zeros(tilesmp,swordslen);
  for k = 1:cframes
    img = zeros(imgy,imgx,3,'uint8');
    if (vid.hasFrame)
      img = vid.readFrame;
    endif
    img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
    for n = 1:tiley
      for m = 1:tilex
        tile = img((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:);
        chunkfull((n-1)*tilex+m,(k-1)*tilergb+(1:tilergb)) = reshape(tile,1,tilergb);
      endfor
    endfor
  endfor
  chunkdata((fc-1)*tilesmp+(1:tilesmp),:) = chunkfull;
endfor


svdcomps = swordslen;
[u, s, v] = svd(chunkdata-128,'econ');
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';


chunkindex1 = [];
chunkindex2 = [];
chunkindex3 = [];
for k = 1:cframes
  chunkindex1 = [chunkindex1 ((k-1)*3+0)*tilesize+(1:tilesize)];
  chunkindex2 = [chunkindex2 ((k-1)*3+1)*tilesize+(1:tilesize)];
  chunkindex3 = [chunkindex3 ((k-1)*3+2)*tilesize+(1:tilesize)];
endfor

mkdir output;
vid = VideoReader(filename);

bn = 6;
for fc = 1:cframes:vframes
  chunkfull = zeros(tilesmp,swordslen);
  for k = 1:cframes
    img = zeros(imgy,imgx,3,'uint8');
    if (vid.hasFrame)
      img = vid.readFrame;
    endif
    img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
    for n = 1:tiley
      for m = 1:tilex
        tile = img((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:);
        chunkfull((n-1)*tilex+m,(k-1)*tilergb+(1:tilergb)) = reshape(tile,1,tilergb);
      endfor
    endfor
  endfor

  chunkfull1 = chunkfull(:,chunkindex1);
  chunkfull2 = chunkfull(:,chunkindex2);
  chunkfull3 = chunkfull(:,chunkindex3);
  chunkmean1 = mean(chunkfull1,2);
  chunkmean2 = mean(chunkfull2,2);
  chunkmean3 = mean(chunkfull3,2);
  chunkmean = [chunkmean1 chunkmean2 chunkmean3];
  chunkcentered1 = chunkfull1 - chunkmean1;
  chunkcentered2 = chunkfull2 - chunkmean2;
  chunkcentered3 = chunkfull3 - chunkmean3;
  chunkcentered = [];
  chunkcentered(:,chunkindex1) = chunkcentered1;
  chunkcentered(:,chunkindex2) = chunkcentered2;
  chunkcentered(:,chunkindex3) = chunkcentered3;

  bb = vinv * chunkcentered';
  sc = (128/bn) / max(abs([min(bb(:)) max(bb(:))]));
  if (isinf(sc)) sc = 1; endif
  bb = cast(fptoint(bb * sc, bn),'int8');
  chunkmean = cast(chunkmean,'uint8');

  savefile = sprintf("output/video%i.mat",fc);
  save("-binary", "-zip", savefile, "bb", "sc", "bn", "chunkmean", "swordslen", "svdcomps", "imgx", "imgy", "tiledim", "tilesize", "tilergb", "tilex", "tiley", "tilesmp");
endfor


clear bb sc;
load "output/video1.mat";
chunkmean = cast(chunkmean,'double');
bb = inttofp(cast(bb,'double'), bn) / sc;
aa = (vv * bb)';
aa1 = aa(:,chunkindex1) + chunkmean(:,1);
aa2 = aa(:,chunkindex2) + chunkmean(:,2);
aa3 = aa(:,chunkindex3) + chunkmean(:,3);
aa = [];
aa(:,chunkindex1) = aa1;
aa(:,chunkindex2) = aa2;
aa(:,chunkindex3) = aa3;

k = 1;
img2 = zeros(tiley*tiledim,tilex*tiledim,3);
for n = 1:tiley
  for m = 1:tilex
    tile = aa((n-1)*tilex+m,(k-1)*tilergb+(1:tilergb));
    img2((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:) = reshape(tile,tiledim,tiledim,3);
  endfor
endfor
img2(img2(:)<0) = 0;
img2(img2(:)>255) = 255;
img2 = cast(img2, "uint8");

img2 = img2(1:imgy,1:imgx,:);
img2 = imsmooth(img2);
figure(2); image(img2); daspect([1 1]); set (gca, "Position", [0 0 1 1]); axis off;

