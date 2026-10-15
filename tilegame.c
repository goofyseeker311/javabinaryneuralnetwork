#include <c64.h>
#include <cbm.h>
#include <conio.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <tgi.h>

typedef struct {
	int x, y;
} vec;
typedef struct {
	vec pos, dir;
} ray;
typedef struct {
	ray loc;
	unsigned char ang;
} ent;

const unsigned char tgipalette[2] = {TGI_COLOR_BLACK, TGI_COLOR_LIGHTBLUE};

#define SCREENWIDTH 40
#define SCREENHEIGHT 25
#define SCREENSIZE 1000
#define TILEDDIM 64
#define TILEDSIZE 4096
#define RAYCOUNT 256
#define RAYSIZE 512
#define FPS 8
#define JIFFY_CLOCK ((unsigned char*)0x00A0)
#define SCREEN_RAM ((unsigned char*)0x8400)
#define BITMAP_RAM ((unsigned char*)0xA000)
#define TILEDROOM ((unsigned char*)0x4000)
#define TILEDSDF ((unsigned char*)0x5000)
#define RAYTABLE ((vec*)0x6000)

bool f=false;
int i=0, j=0, a=0, b=0, c=0, d=0;
char x=0, y=0, z=0, w=0;
unsigned int k=0;
unsigned char l=0, m=0, n=0, o=0, p=0;
unsigned long time1, time2, timedif;

ent player = {2<<FPS,3<<FPS,0,1,0};
ray screenray = {0};

unsigned long gettime() {
	return (((long)JIFFY_CLOCK[2])<<16) | (JIFFY_CLOCK[1]<<8) | JIFFY_CLOCK[0];
}

unsigned int loadfile(const char* filename, unsigned memory) {
	cbm_k_setlfs(1, 8, 0);
	cbm_k_setnam(filename);
	return cbm_k_load(0, memory);
}

void main(void) {
	bzero(TILEDROOM, TILEDSIZE);
	bzero(TILEDSDF, TILEDSIZE);
	bzero(RAYTABLE, RAYSIZE*4);
	k = loadfile("tiledroom", (unsigned)TILEDROOM);
	l = cbm_k_readst();
	printf("lf0: %u - %u: %u, %u, %u, %u\n",l,k,TILEDROOM[0],TILEDROOM[1],TILEDROOM[2],TILEDROOM[3]);
	k = loadfile("tiledsdf", (unsigned)TILEDSDF);
	l = cbm_k_readst();
	printf("lf1: %u - %u: %u, %u, %u, %u\n",l,k,TILEDSDF[0],TILEDSDF[1],TILEDSDF[2],TILEDSDF[3]);
	k = loadfile("tiledata2", (unsigned)RAYTABLE);
	l = cbm_k_readst();
	printf("lf2: %u - %u: %d, %d, %d, %d\n",l,k,RAYTABLE[0].x,RAYTABLE[0].y,RAYTABLE[1].x,RAYTABLE[1].y);
	time1 = gettime();
	for (l=0;l<SCREENWIDTH;l++) {
		p = (player.ang<<3)+(player.ang<<5) + l;
		screenray.pos = player.loc.pos;
		screenray.dir = RAYTABLE[p];
		f = false;
		o = 0;
		do {
			x = screenray.pos.x>>FPS;
			y = screenray.pos.y>>FPS;
			if (((x&0b11000000)==0)&&((y&0b11000000)==0)) {
				i = (y<<6)+x;
				m = TILEDROOM[i];
				if (m==0) {
					n = TILEDSDF[i];
					screenray.pos.x += screenray.dir.x<<n;
					screenray.pos.y += screenray.dir.y<<n;
					o += 1<<n;
				} else {
					f = true;
					//printf("%u,",o);
				}
			} else {
				f = true;
				m = 255;
				//printf("%u,",o);
			}
		} while(!f);
	}
	time2 = gettime();
	timedif = time2 - time1;
	printf("\ntimedif: %u\n",timedif);
	cgetc();

	bgcolor(COLOR_ORANGE);
	bordercolor(COLOR_CYAN);
	textcolor(COLOR_GREEN);
	clrscr();
	printf("Init.\n");
	cgetc();

	tgi_install(tgi_static_stddrv);
	tgi_init();
	tgi_setpalette(tgipalette);
	tgi_clear();
	tgi_setcolor(1);
	tgi_circle(160,100,20);
	cgetc();
	tgi_done();

	CIA2.pra = (CIA2.pra&0b11111100)|0b01;
	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00100000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	VIC.addr = 0b00011000;
	bzero(BITMAP_RAM, SCREENSIZE*8);
	bzero(SCREEN_RAM, SCREENSIZE);
	SCREEN_RAM[0] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[1] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[2] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[3] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[4] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[5] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[6] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	SCREEN_RAM[7] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	BITMAP_RAM[0] = 0xFF;
	BITMAP_RAM[1] = 0xAA;
	BITMAP_RAM[2] = 0xFF;
	BITMAP_RAM[3] = 0xAA;
	BITMAP_RAM[4] = 0xAA;
	BITMAP_RAM[5] = 0xFF;
	BITMAP_RAM[6] = 0xAA;
	BITMAP_RAM[7] = 0xFF;
	cgetc();

	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00000000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	VIC.addr = 0b00010100;
	memset(SCREEN_RAM, 96, SCREENSIZE);
	memset(COLOR_RAM, COLOR_WHITE, SCREENSIZE);
	COLOR_RAM[10*SCREENWIDTH+20] = COLOR_YELLOW;
	SCREEN_RAM[10*SCREENWIDTH+20] = 91;
	COLOR_RAM[20*SCREENWIDTH+30] = COLOR_RED;
	SCREEN_RAM[20*SCREENWIDTH+30] = 1;
	cgetc();

	CIA2.pra = (CIA2.pra&0b11111100)|0b11;
	VIC.addr = 0b00010110;
	tgi_init();
	tgi_setpalette(tgipalette);
	cgetc();
	tgi_done();

	bgcolor(COLOR_BLUE);
	bordercolor(COLOR_LIGHTBLUE);
	textcolor(COLOR_LIGHTBLUE);
	printf("exit.\n");
}