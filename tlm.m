clear; output_precision(16);

filename = "words.txt";
fid = fopen(filename);
words = textscan(fid, "%s");
words = words{1};
fclose (fid);

wordsn = size(words,1);

for n = 1:wordsn
  wordsnind = 255 + n;
  words(n, 2) = wordsnind;
  byteword = unicode2native(words{n,1}, "ISO-8859-1");
  bwordm = size(byteword,2);

  bwords(n,1) = wordsnind;
  for m = 1:bwordm
    bwords(n,m+1) = byteword(1,m);
  endfor
endfor


