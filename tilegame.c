#include <c64.h>
#include <cbm.h>
#include <conio.h>
#include <joystick.h>
#include <mouse.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <tgi.h>

#undef DYN_DRV
#define DYN_DRV 0

typedef struct vector {
	signed char x, y;
} vec;
typedef struct pointray {
	vec pos, dir;
} ray;
typedef struct entity {
	vec pos, dir, rgt;
	int angfwd, angrgt;
	int indfwd, indrgt;
} ent;

const unsigned char tgipalette[2] = {TGI_COLOR_BLACK, TGI_COLOR_LIGHTBLUE};

#define DYN_DRV 0
#define CHARACTERSIZE 0x800
#define SCREENWIDTH 40
#define SCREENHEIGHT 25
#define SCREENSIZE 1000
#define TILEDDIM 16
#define TILEDSIZE 256
#define RAYCOUNT 256
#define RAYSIZE 512
#define FPS 3
#define CHARACTER_ROM_CONFIG ((unsigned char*)0x0001)
#define JIFFY_CLOCK ((unsigned char*)0x00A0)
#define DEFAULT_TEXT_RAM ((unsigned char*)0x0400)
#define CHARACTER_RAM ((unsigned char*)0x3800)
#define TILEDROOM ((unsigned char*)0x4000)
#define TILEDSDF ((unsigned char*)0x5000)
#define RAYTABLE ((vec*)0x6000)
#define TEXT_RAM ((unsigned char*)0x8800)
#define SCREEN_RAM ((unsigned char*)0x8C00)
#define IMAGE_RAM ((unsigned char*)0x9C00)
#define BITMAP_RAM ((unsigned char*)0xA000)
#define CHARACTER_ROM ((unsigned char*)0xD000)

bool f=false;
int i=0, j=0, c=0, d=0;
char x=0, y=0, z=0, w=0, a=0, b=0;
unsigned int k=0, q=0, r=0, s=0, t=0;
unsigned char l=0, m=0, n=0, o=0, p=0, u=0, v=0;
unsigned char c1=0, c2=0, c3=0, v1=0, v2=0, v3=0;
unsigned long time1=0, time2=0, timedif=0;
unsigned char shufflestep = 0;
char *ostr = "key:          ";
struct mouse_info mouseinfo, mouseold;
unsigned char joycount;

ent player = {2<<FPS,3<<FPS,1<<FPS,0<<FPS,0<<FPS,1<<FPS,30,0,0,0};
ray screenray = {0};

unsigned long gettime() {
	return (((long)JIFFY_CLOCK[2])<<16) | (JIFFY_CLOCK[1]<<8) | JIFFY_CLOCK[0];
}

unsigned int loadfile(const char* filename, unsigned memory) {
	cbm_k_setlfs(1, 8, 0);
	cbm_k_setnam(filename);
	return cbm_k_load(0, memory);
}

void changeplayerdir() {
	if (player.angfwd<0) {
		player.angfwd = 31;
	} else if (player.angfwd>31) {
		player.angfwd = 0;
	}
	if (player.angrgt<0) {
		player.angrgt = 31;
	} else if (player.angrgt>31) {
		player.angrgt = 0;
	}
	player.indfwd = (player.angfwd<<5) + (player.angfwd<<3);
	player.dir = RAYTABLE[player.indfwd+20];
	player.indrgt = (player.angrgt<<5) + (player.angrgt<<3);
	player.rgt = RAYTABLE[player.indrgt+20];
}

void handlekeyboard() {
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
				player.angrgt += 1;
				changeplayerdir();
				sprintf(ostr, "key: rgt.    ");
			break;
			case 157:
				player.angfwd -= 1;
				player.angrgt -= 1;
				changeplayerdir();
				sprintf(ostr, "key: lft.    ");
			break;
			default:
				sprintf(ostr, "key: %d      ",a);
			break;
		}
		cputsxy(0, 24, ostr);
	}
}

void handlemouse() {
	mouse_info(&mouseinfo);
	if (mouseinfo.pos.x!=mouseold.pos.x) {
		c = mouseinfo.pos.x - mouseold.pos.x;
		if (c>0) {
			player.angfwd += 1;
			player.angrgt += 1;
			changeplayerdir();
			sprintf(ostr, "mse: rgt.    ");
		} else if (c<0) {
			player.angfwd -= 1;
			player.angrgt -= 1;
			changeplayerdir();
			sprintf(ostr, "mse: lft.    ");
		}
		cputsxy(0, 24, ostr);
	}
	mouseold.pos.x = 160;
	mouseold.pos.y = 100;
	mouse_move(mouseold.pos.x, mouseold.pos.y);
}

void handlejoystick() {
	joycount = joy_count();
	if (joycount>1) {
		u = joy_read(1);
		if (u!=0) {
			switch(u) {
				case JOY_UP_MASK:
					player.pos.x += player.dir.x;
					player.pos.y += player.dir.y;
					sprintf(ostr, "joy: fwd.    ");
				break;
				case JOY_DOWN_MASK:
					player.pos.x -= player.dir.x;
					player.pos.y -= player.dir.y;
					sprintf(ostr, "joy: bck.    ");
				break;
				case JOY_RIGHT_MASK:
					player.angfwd += 1;
					player.angrgt += 1;
					changeplayerdir();
					sprintf(ostr, "joy: rgt.    ");
				break;
				case JOY_UP_MASK|JOY_RIGHT_MASK:
					player.pos.x += player.dir.x;
					player.pos.y += player.dir.y;
					player.angfwd += 1;
					player.angrgt += 1;
					changeplayerdir();
					sprintf(ostr, "joy: fwr.    ");
				break;
				case JOY_LEFT_MASK:
					player.angfwd -= 1;
					player.angrgt -= 1;
					changeplayerdir();
					sprintf(ostr, "joy: lft.    ");
				break;
				case JOY_UP_MASK|JOY_LEFT_MASK:
					player.pos.x += player.dir.x;
					player.pos.y += player.dir.y;
					player.angfwd -= 1;
					player.angrgt -= 1;
					changeplayerdir();
					sprintf(ostr, "joy: fwl.    ");
				break;
				case JOY_RIGHT_MASK|JOY_DOWN_MASK:
					player.pos.x += player.rgt.x;
					player.pos.y += player.rgt.y;
					sprintf(ostr, "joy: srt.    ");
				break;
				case JOY_LEFT_MASK|JOY_DOWN_MASK:
					player.pos.x -= player.rgt.x;
					player.pos.y -= player.rgt.y;
					sprintf(ostr, "joy: slt.    ");
				break;
				default:
					sprintf(ostr, "joy: %u ",u);
				break;
			}
			cputsxy(0, 24, ostr);
		}
	}
}

void drawvline(bool hit) {
	p = o>>1;
	if (p>12) {
		p = 12;
	}
	v1 = 224;
	c1 = COLOR_LIGHTBLUE;
	v2 = 224;
	c2 = COLOR_LIGHTBLUE;
	v3 = 250;
	c3 = COLOR_LIGHTGREEN;
	if (hit) {
		v2 = 93;
		switch(p) {
			case 12: case 11: case 10: case 9: case 8:
				c2 = COLOR_BLACK;
			break;
			case 7: case 6:
				c2 = COLOR_GRAY1;
			break;
			case 5: case 4:
				c2 = COLOR_GRAY2;
			break;
			case 3: case 2:
				c2 = COLOR_GRAY3;
			break;
			case 1: case 0:
				c2 = COLOR_WHITE;
			break;
			default:
				c2 = COLOR_CYAN;
			break;
		}
	}
	q = l;
	for (u=0;u<p;q+=40,u++) {
		DEFAULT_TEXT_RAM[q] = v1;
		COLOR_RAM[q] = c1;
	}
	for (u=0;u<(24-p-p);q+=40,u++) {
		DEFAULT_TEXT_RAM[q] = v2;
		COLOR_RAM[q] = c2;
	}
	for (u=0;u<p;q+=40,u++) {
		DEFAULT_TEXT_RAM[q] = v3;
		COLOR_RAM[q] = c3;
	}
}

void main(void) {
	joy_install(joy_static_stddrv);
	mouse_install(&mouse_def_callbacks, mouse_static_stddrv);

	bzero(TILEDROOM, TILEDSIZE);
	bzero(TILEDSDF, TILEDSIZE);
	bzero(RAYTABLE, RAYSIZE*4);
	bzero(TEXT_RAM, SCREENSIZE);
	bzero(SCREEN_RAM, SCREENSIZE);
	bzero(BITMAP_RAM, SCREENSIZE*8);
	k = loadfile("tiledroom", (unsigned)TILEDROOM);
	l = cbm_k_readst();
	printf("lf0: %u - %u: %u, %u, %u, %u\n",l,k,TILEDROOM[0],TILEDROOM[1],TILEDROOM[2],TILEDROOM[3]);
	k = loadfile("tiledsdf", (unsigned)TILEDSDF);
	l = cbm_k_readst();
	printf("lf1: %u - %u: %u, %u, %u, %u\n",l,k,TILEDSDF[0],TILEDSDF[1],TILEDSDF[2],TILEDSDF[3]);
	k = loadfile("tiledata2", (unsigned)RAYTABLE);
	l = cbm_k_readst();
	printf("lf2: %u - %u: %d, %d, %d, %d\n",l,k,RAYTABLE[0].x,RAYTABLE[0].y,RAYTABLE[1].x,RAYTABLE[1].y);
	k = loadfile("tileimage", (unsigned)IMAGE_RAM);
	l = cbm_k_readst();
	printf("lf3: %u - %u: %d, %d, %d, %d\n",l,k,IMAGE_RAM[0],IMAGE_RAM[1],IMAGE_RAM[2],IMAGE_RAM[3]);
	memcpy(SCREEN_RAM, IMAGE_RAM, SCREENSIZE);
	cputcxy(0,0,'a');
	cgetc();

	CIA1.cra = CIA1.cra&0xFE;
	CHARACTER_ROM_CONFIG[0] = CHARACTER_ROM_CONFIG[0]&0xFB;
	memcpy(CHARACTER_RAM, CHARACTER_ROM+0x800, CHARACTERSIZE);
	for (l=0;l<8;l+=2) {
		CHARACTER_RAM[744+l+0] = 0xaa;
		CHARACTER_RAM[744+l+1] = 0x55;
	}
	CHARACTER_ROM_CONFIG[0] = CHARACTER_ROM_CONFIG[0]|0x4;
	CIA1.cra = CIA1.cra|0x1;
	VIC.addr = 0b00011110;
	bordercolor(COLOR_BLACK);
	bgcolor(COLOR_GRAY1);
	textcolor(COLOR_WHITE);
	clrscr();
	while (w==0) {
		time1 = gettime();
		handlekeyboard();
		handlemouse();
		handlejoystick();
		shufflestep+=5;
		if (shufflestep>=8) {
			shufflestep-=8;
		}
		k = player.indfwd + (SCREENWIDTH-1);
		for (l=shufflestep;l<SCREENWIDTH;l+=8) {
			screenray.pos = player.pos;
			screenray.dir = RAYTABLE[k-l];
			f = false;
			o = 0;
			do {
				x = screenray.pos.x>>FPS;
				y = screenray.pos.y>>FPS;
				if (((x&0b11110000)==0)&&((y&0b11110000)==0)) {
					u = (y<<4)+x;
					m = TILEDROOM[u];
					if (m==0) {
						n = TILEDSDF[u];
						screenray.pos.x += screenray.dir.x<<n;
						screenray.pos.y += screenray.dir.y<<n;
						o += 1<<n;
					} else {
						f = true;
						drawvline(true);
					}
				} else {
					f = true;
					m = 255;
					drawvline(false);
				}
			} while(!f);
		}
		time2 = gettime();
		timedif = time2 - time1;
		sprintf(ostr, "jcd: %u     ",timedif);
		cputsxy(25, 24, ostr);
	}
	cgetc();

	VIC.addr = 0b00010110;
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
	VIC.addr = 0b00111000;
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
	VIC.addr = 0b00100100;
	memset(COLOR_RAM, COLOR_WHITE, SCREENSIZE);
	memset(TEXT_RAM, 96, SCREENSIZE);
	COLOR_RAM[10*SCREENWIDTH+20] = COLOR_YELLOW;
	TEXT_RAM[10*SCREENWIDTH+20] = 91;
	COLOR_RAM[20*SCREENWIDTH+30] = COLOR_RED;
	TEXT_RAM[20*SCREENWIDTH+30] = 1;
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