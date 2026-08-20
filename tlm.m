clear; output_precision(16);

filename = "words.txt";
fid = fopen(filename);
words = textscan(fid, "%s");
words = words{1};
fclose (fid);

wordsn = size(words,1);

for n = 1:wordsn
  byteword = unicode2native(words{n,1}, "ISO-8859-1");
  bwordm = size(byteword,2);
  for m = 1:bwordm
    bwords(n,m) = byteword(1,m);
  endfor
endfor


