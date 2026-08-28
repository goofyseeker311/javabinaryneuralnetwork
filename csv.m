close all; clear; output_precision(16);

filename = "words.csv";
fid = fopen(filename);
words = textscan(fid, "%s%s%s%s%s%[^\n]", "Delimiter", ",");
words = words{2};
fclose (fid);

wordsn = size(words,1)-2;
words = lower(words(2:(wordsn+1),:));
printf("words loaded (%i).\n",wordsn);

filename = "words.txt";
fid = fopen(filename, "w");
for n = 1:wordsn
  fprintf(fid,"%s\n",words{n});
endfor
fclose (fid);

