close all; clear; output_precision(16);

pkg load video;

load tpm.mat;
swordslen = size(vinv,1);
svdcomps = swordslen;
v = eye(swordslen)/vinv;
vv = v(:,1:svdcomps);

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

mkdir output;
data = zeros(tilesmp,tilergb);

for fn = 1:vframes
  img = vid.readFrame;

  img(tiley*tiledim,tilex*tiledim,:) = [0,0,0];
  for n = 1:tiley
    for m = 1:tilex
      tile = img((n-1)*tiledim+(1:16),(m-1)*tiledim+(1:16),:);
      data((n-1)*tilex+m,:) = reshape(tile,1,tilergb);
    endfor
  endfor

  swordsfull = cast(data,"double");
  swordsmean = mean(swordsfull,1);
  swordscentered = swordsfull - swordsmean;

  bb = vinv * swordscentered';
  sc = 128 / max(abs([min(bb(:)) max(bb(:))]));
  bb = cast(bb * sc,'int8');

  savefile = sprintf("output/video%i.mat",fn);
  save("-binary", "-zip", savefile, "bb", "sc", "swordsmean", "swordslen", "svdcomps", "tilex", "tiley", "tiledim", "imgx", "imgy");
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


