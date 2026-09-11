close all; clear; output_precision(16);

pkg load video;

vid = VideoReader("video.mp4");
vframes = vid.NumberOfFrames;
imgx = vid.Width;
imgy = vid.Height;

cframes = 8;
chunks = ceil(vframes/cframes);

tiledim = 8;
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
[u, s, v] = svd(chunkdata,'econ');
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';


mkdir output;

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

  chunkmean = mean(chunkfull,1);
  chunkcentered = chunkfull - chunkmean;

  bb = vinv * chunkcentered';
  sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
  if (isinf(sc)) sc = 1; endif
  bb = cast(bb * sc,'int8');

  savefile = sprintf("output/video%i.mat",fc);
  save("-binary", "-zip", savefile, "bb", "sc", "chunkmean", "swordslen", "svdcomps", "imgx", "imgy", "tiledim", "tilesize", "tilergb", "tilex", "tiley", "tilesmp");
endfor


clear bb sc;
load "output/video1.mat";
bb = cast(bb,'double') / sc;
aa = (vv * bb)' + chunkmean;

img2 = zeros(tiley*tiledim,tilex*tiledim,3);
k = 1;
for n = 1:tiley
  for m = 1:tilex
    tile = aa((n-1)*tilex+m,(k-1)*tilergb+(1:tilergb));
    img2((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:) = reshape(tile,tiledim,tiledim,3);
  endfor
endfor
img2 = cast(img2, "uint8");

img2 = img2(1:imgy,1:imgx,:);
figure(2); image(img2); daspect([1 1]);

