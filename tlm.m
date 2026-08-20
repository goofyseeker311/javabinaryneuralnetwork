clear; output_precision(16);

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
    bwords(n,m+1) = cast(byteword(1,m),"int64") + 255*(m-1);
  endfor
endfor

bwordsm = size(bwords,2)-1;
bwordsm2 = bwordsm * 255 ;

for n = 1:wordsn
  wordsnind = bwordsm2 + n;
  words(n,2) = wordsnind;
  bwords(n,1) = wordsnind;
endfor


