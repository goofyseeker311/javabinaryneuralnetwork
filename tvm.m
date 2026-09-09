close all; clear; output_precision(16);

pkg load video;

load tpm.mat;
svdcomps = 100;
vinv = vinv(1:svdcomps,:);
swordslen = size(vinv,1);
vv = (eye(swordslen)/vinv')';

vid = VideoReader("video.mp4");
vframes = vid.NumberOfFrames;
imgx = vid.Width;
imgy = vid.Height;

tiledim = 16;
tilesize = tiledim^2;
tilergb = tilesize*3;
tilex = ceil(imgx/tiledim);
tiley = ceil(imgy/tiledim);
tilesmp = tilex*tiley;

cframes = 32;
chunkorigins = 1:cframes;
chunkscales = ones(1,cframes);
chunkmeans = zeros(tilergb,cframes);
chunkdata = ones(svdcomps,tilesmp,cframes,'int8');

mkdir output;
words = zeros(tilesmp,tilergb,cframes);


for fc = 1:cframes:vframes

  for k = 1:cframes
    img = vid.readFrame;
    img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
    for n = 1:tiley
      for m = 1:tilex
        tile = img((n-1)*tiledim+(1:16),(m-1)*tiledim+(1:16),:);
        words((n-1)*tilex+m,:,k) = reshape(tile,1,tilergb);
      endfor
    endfor
  endfor

  chunkfull = cast(words,"double");
  chunkmeans = mean(chunkfull,1);
  chunkcentered = chunkfull - chunkmeans;

  for fn = 1:cframes
    bb = vinv * chunkcentered(:,:,fn)';
    sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
    if (isinf(sc)) sc = 1; endif
    bb = cast(bb * sc,'int8');
    bbz = sum(bb(:)==0);
    corigin = fn;
    if (fn>1)
      bb2 = vinv * (chunkcentered(:,:,fn)-chunkcentered(:,:,fn-1))';
      sc2 = 128 / max(abs([min(bb2(:)) max(bb2(:))]));
      if (isinf(sc2)) sc2 = 1; endif
      bb2 = cast(bb2 * sc2,'int8');
      bbz2 = sum(bb2(:)==0);
      if (bbz2>bbz)
        bb = bb2;
        sc = sc2;
        corigin = fn - 1;
      endif
    endif
    chunkorigins(1,fn) = corigin;
    chunkscales(1,fn) = sc;
    chunkdata(:,:,fn) = bb;
  endfor

  savefile = sprintf("output/video%i.mat",fc);
  save("-binary", "-zip", savefile, "chunkdata", "chunkorigins", "chunkscales", "chunkmeans", "swordslen", "svdcomps", "tilex", "tiley", "tiledim", "imgx", "imgy");
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


