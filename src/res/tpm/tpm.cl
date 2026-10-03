#define tpmtiledim 16
#define tpmtilesize 256
#define tpmtilergb 768

kernel void compressimage(global int *img, global int *imgp, global char *img2);

kernel void compressimage(global int *img, global int *imgp, global char *img2) {
	unsigned int xid = get_global_id(0);
	unsigned int yid = get_global_id(1);
	int tpmwidth = imgp[0];
	int tpmheight = imgp[1];
	int tpmtilex = imgp[2];
	int tpmtiley = imgp[3];
	printf("tile: %i,%i = %i. (%i,%i,%i,%i)\n",xid,xid,img[0],tpmwidth,tpmheight,tpmtilex,tpmtiley);
	for (int j=0;j<tpmtiledim;j++) {
		for (int i=0;i<tpmtiledim;i++) {
			int pixely = yid*tpmtiledim+j;
			int pixelx = xid*tpmtiledim+i;
			int pixelcolor = 0;
			if ((pixelx<tpmwidth)&&(pixely<tpmheight)) {
				pixelcolor = img[pixely*tpmwidth+pixelx];
			}
			/*
			int svdy = i*tpmtiledim+j;
			int svdx = y*tpmtilex+x;
			img2[tpmtilesize*0+svdy][svdx] = (pixelcolor>>16) & 0xff;
			img2[tpmtilesize*1+svdy][svdx] = (pixelcolor>>8) & 0xff;
			img2[tpmtilesize*2+svdy][svdx] = pixelcolor & 0xff;
			*/
		}
	}
}
