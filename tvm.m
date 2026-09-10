close all; clear; output_precision(16);

pkg load video;

vid = VideoReader("video.mp4");
vframes = vid.NumberOfFrames;
imgx = vid.Width;
imgy = vid.Height;

chunks = 16;
framestep = vframes / chunks;

cframes = 16;
tiledim = 16;
tilesize = tiledim^2;
tilergb = tilesize*3;
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
tilesmp = tilex*tiley;
swordslen = tilergb*cframes;

chunkdata = zeros(tilesmp*chunks,swordslen,'int8');

for fc = 1:chunks
  chunkfull = zeros(tilesmp,swordslen);
  for k = 1:cframes
    img = vid.readFrame;
    img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
    for n = 1:tiley
      for m = 1:tilex
        tile = img((n-1)*tiledim+(1:tiledim),(m-1)*tiledim+(1:tiledim),:);
        chunkfull((n-1)*tilex+m,(k-1)*tilergb+(1:tilergb)) = reshape(tile,1,tilergb);
      endfor
    endfor
  endfor
  for k = 1:(framestep-1)
    img = vid.readFrame;
  endfor
  chunkdata((fc-1)*tilesmp+(1:tilesmp),:) = chunkfull;
endfor


svdcomps = 100;
[u, s, v] = svd(chunkdata);
vv = v(:,1:svdcomps);
vinv = (eye(swordslen)/vv')';


mkdir output;

for fc = 1:cframes:vframes
  chunkfull = zeros(tilesmp,swordslen);
  for k = 1:cframes
    img = vid.readFrame;
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

  bb = vinv * chunkcentered(:,:,fn)';
  sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
  if (isinf(sc)) sc = 1; endif
  bb = cast(bb * sc,'int8');

  savefile = sprintf("output/video%i.mat",fc);
  save("-binary", "-zip", savefile, "bb", "sc", "chunkmean", "swordslen", "svdcomps", "tilex", "tiley", "tiledim", "imgx", "imgy");
endfor

#save -binary -zip video.mat store sc swordsmean swordslen svdcomps tilex tiley tiledim imgx imgy;

##clear bb sc vv sd;
##load image.mat;
##bb = cast(bb,'double') / sc;
##vv = cast(vv,'double') / sd;
##
##aa = (vv * bb)' + swordsmean;
##cc = svdcomps / swordslen;
##ad = data - aa;
##dd = mean(abs(ad(:)));
##dds = std(ad(:));
##
##img2 = zeros(tiley*tiledim,tilex*tiledim,3);
##for n = 1:tiley
##  for m = 1:tilex
##    tile = aa((n-1)*tilex+m,:);
##    img2((n-1)*tiledim+(1:16),(m-1)*tiledim+(1:16),:) = reshape(tile,tiledim,tiledim,3);
##  endfor
##endfor
##img2 = cast(img2, "uint8");
##
##img = img(1:imgy,1:imgx,:);
##img2 = img2(1:imgy,1:imgx,:);


