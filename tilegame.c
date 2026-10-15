#include <c64.h>
#include <cbm.h>
#include <conio.h>
#include <joystick.h>
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
	vec pos, dir, rgt;
	unsigned char angfwd, angrgt;
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
int i=0, j=0, c=0, d=0;
char x=0, y=0, z=0, w=0, a=0, b=0;
unsigned int k=0, q=0, r=0, s=0, t=0;
unsigned char l=0, m=0, n=0, o=0, p=0;
unsigned long time1, time2, timedif;
char *ostr = "key:          ";

ent player = {2<<FPS,3<<FPS,1<<FPS,0<<FPS,0<<FPS,1<<FPS,30,0};
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
	joy_load_driver(joy_static_stddrv);

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
	cputcxy(0,0,'a');
	cgetc();

	bordercolor(COLOR_BLACK);
	bgcolor(COLOR_GRAY1);
	textcolor(COLOR_WHITE);
	clrscr();
	while (w==0) {
		if(kbhit()!=0) {
			a = cgetc();
			switch (a) {
				case 3:
					w = 1;
					sprintf(ostr, "key: exit.   ");
				break;
				case 87:
				case 145:
					player.pos.x += player.dir.x;
					player.pos.y += player.dir.y;
					sprintf(ostr, "key: fwd.    ");
				break;
				case 83:
				case 17:
					player.pos.x -= player.dir.x;
					player.pos.y -= player.dir.y;
					sprintf(ostr, "key: bck.    ");
				break;
				case 68:
					player.pos.x += player.rgt.x;
					player.pos.y += player.rgt.y;
					sprintf(ostr, "key: srt.    ");
				break;
				case 65:
					player.pos.x -= player.rgt.x;
					player.pos.y -= player.rgt.y;
					sprintf(ostr, "key: slt.    ");
				break;
				case 29:
					player.angfwd += 1;
					if (player.angfwd>=40) {
						player.angfwd = 0;
					}
					player.angrgt += 1;
					if (player.angrgt>=40) {
						player.angrgt = 0;
					}
					k = (player.angfwd<<3)+(player.angfwd<<5);
					player.dir = RAYTABLE[k+20];
					k = (player.angrgt<<3)+(player.angrgt<<5);
					player.rgt = RAYTABLE[k+20];
					sprintf(ostr, "key: rgt.    ");
				break;
				case 157:
					player.angfwd -= 1;
					if (player.angfwd>=40) {
						player.angfwd = 39;
					}
					player.angrgt -= 1;
					if (player.angrgt>=40) {
						player.angrgt = 39;
					}
					k = (player.angfwd<<3)+(player.angfwd<<5);
					player.dir = RAYTABLE[k+20];
					k = (player.angrgt<<3)+(player.angrgt<<5);
					player.rgt = RAYTABLE[k+20];
					sprintf(ostr, "key: lft.    ");
				break;
				default:
					sprintf(ostr, "key: %d      ",a);
				break;
			}
			cputsxy(0, 24, ostr);
		}
		time1 = gettime();
		k = (player.angfwd<<3)+(player.angfwd<<5) + (SCREENWIDTH-1);
		for (l=0;l<SCREENWIDTH;l++) {
			screenray.pos = player.pos;
			screenray.dir = RAYTABLE[k-l];
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
						p = o>>1;
						if (p>12) {
							p = 12;
						}
						textcolor(COLOR_LIGHTBLUE);
						cvlinexy(l, 0, p);
						textcolor(COLOR_GRAY2);
						cvlinexy(l, p, (12-p)<<1);
						textcolor(COLOR_LIGHTGREEN);
						cvlinexy(l, 24-p, p);
					}
				} else {
					f = true;
					m = 255;
					p = o>>1;
					if (p>12) {
						p = 12;
					}
					textcolor(COLOR_LIGHTBLUE);
					cvlinexy(l, 0, p);
					textcolor(COLOR_LIGHTRED);
					cvlinexy(l, p, (12-p)<<1);
					textcolor(COLOR_LIGHTGREEN);
					cvlinexy(l, 24-p, p);
				}
			} while(!f);
		}
		time2 = gettime();
		timedif = time2 - time1;
		sprintf(ostr, "jcd: %u   ",timedif);
		cputsxy(20, 24, ostr);
	}
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