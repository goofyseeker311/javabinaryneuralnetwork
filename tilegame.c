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

typedef union unionchar {
	signed char d;
	unsigned char u;
} udchar;
typedef struct charvector {
	udchar x, y, a, l;
} charvec;
typedef struct pointray {
	charvec pos, dir;
} ray;
typedef struct entity {
	charvec pos, dir, rgt, loc;
	int angfwd, angrgt;
	int indfwd, indrgt;
	unsigned char movement;
} ent;

const unsigned char tgipalette[2] = {TGI_COLOR_BLACK, TGI_COLOR_LIGHTBLUE};

#define CHARACTERSIZE 0x800
#define SCREENWIDTH 40
#define SCREENHEIGHT 25
#define SCREENSIZE 1000
#define TILEDDIM 32
#define TILEDSIZE 1024
#define RAYCOUNT 1280
#define RAYSIZE 2560
#define FPS 3
#define CHARACTER_ROM_CONFIG ((unsigned char*)0x0001)
#define JIFFY_CLOCK ((unsigned char*)0x00A0)
#define DEFAULT_TEXT_RAM ((unsigned char*)0x0400)
#define TILEDROOM ((unsigned char*)0x5000)
#define TILEDSDF ((unsigned char*)0x5800)
#define RAYTABLE ((charvec*)0x6000)
#define RAYTABLE2 ((charvec*)0x7800)
#define CHARACTER_RAM ((unsigned char*)0x8000)
#define TEXT_RAM ((unsigned char*)0x8800)
#define SPRITE_RAM ((unsigned char*)0x8BF8)
#define SCREEN_RAM ((unsigned char*)0x8C00)
#define COLUMN_ZBUFFER ((charvec*)0x9000)
#define IMAGE_RAM ((unsigned char*)0x9C00)
#define BITMAP_RAM ((unsigned char*)0xA000)
#define CHARACTER_ROM ((unsigned char*)0xD000)

bool e=false, f=false;
int i=0, j=0, c=0, d=0;
signed char x=0, y=0, z=0, w=0;
char a=0, b=0;
unsigned int k=0, q=0, r=0, s=0, t=0;
unsigned char l=0, m=0, n=0, o=0, p=0, u=0, v=0;
unsigned char c1=0, c2=0, c3=0, v1=0, v2=0, v3=0;
long time1=0, time2=0, timedif=0;
unsigned char shufflestep = 0;
char *ostr = "key:          ";
struct mouse_info mouseinfo, mouseold;
unsigned char joycount;

ent player = {2<<FPS,3<<FPS,0,0,1<<FPS,0<<FPS,0,0,0<<FPS,1<<FPS,0,0,2,3,0,0,24,0,0,0,0};
ray screenray = {0};

long gettime() {
	return (((long)JIFFY_CLOCK[2])<<16) | (((long)JIFFY_CLOCK[1])<<8) | ((long)JIFFY_CLOCK[0]);
}

unsigned int loadfile(const char* filename, unsigned memory) {
	cbm_k_setlfs(1, 8, 0);
	cbm_k_setnam(filename);
	return cbm_k_load(0, memory);
}

void handlekeyboard() {
	if(kbhit()!=0) {
		a = cgetc();
		switch (a) {
			case 3:
				e = true;
				sprintf(ostr, "key: exit.   ");
			break;
			case 87:
			case 145:
				player.movement = player.movement | 0b00000001;
				sprintf(ostr, "key: fwd.    ");
			break;
			case 83:
			case 17:
				player.movement = player.movement | 0b00000010;
				sprintf(ostr, "key: bck.    ");
			break;
			case 68:
				player.movement = player.movement | 0b00000100;
				sprintf(ostr, "key: srt.    ");
			break;
			case 65:
				player.movement = player.movement | 0b00001000;
				sprintf(ostr, "key: slt.    ");
			break;
			case 29:
				player.movement = player.movement | 0b00010000;
				sprintf(ostr, "key: rgt.    ");
			break;
			case 157:
				player.movement = player.movement | 0b00100000;
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
			player.movement = player.movement | 0b00010000;
			sprintf(ostr, "mse: rgt.    ");
		} else if (c<0) {
			player.movement = player.movement | 0b00100000;
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
					player.movement = player.movement | 0b00000001;
					sprintf(ostr, "joy: fwd.    ");
				break;
				case JOY_DOWN_MASK:
					player.movement = player.movement | 0b00000010;
					sprintf(ostr, "joy: bck.    ");
				break;
				case JOY_RIGHT_MASK:
					player.movement = player.movement | 0b00010000;
					sprintf(ostr, "joy: rgt.    ");
				break;
				case JOY_UP_MASK|JOY_RIGHT_MASK:
					player.movement = player.movement | 0b00010001;
					sprintf(ostr, "joy: fwr.    ");
				break;
				case JOY_LEFT_MASK:
					player.movement = player.movement | 0b00100000;
					sprintf(ostr, "joy: lft.    ");
				break;
				case JOY_UP_MASK|JOY_LEFT_MASK:
					player.movement = player.movement | 0b00100001;
					sprintf(ostr, "joy: fwl.    ");
				break;
				case JOY_RIGHT_MASK|JOY_DOWN_MASK:
					player.movement = player.movement | 0b00000100;
					sprintf(ostr, "joy: srt.    ");
				break;
				case JOY_LEFT_MASK|JOY_DOWN_MASK:
					player.movement = player.movement | 0b00001000;
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

void handlemovement() {
	screenray.pos = player.pos;
	if ((player.movement&0b00000001)!=0) {
		screenray.pos.x.d = player.pos.x.d + player.dir.x.d;
		screenray.pos.y.d = player.pos.y.d + player.dir.y.d;
	}
	if ((player.movement&0b00000010)!=0) {
		screenray.pos.x.d = player.pos.x.d - player.dir.x.d;
		screenray.pos.y.d = player.pos.y.d - player.dir.y.d;
	}
	if ((player.movement&0b00000100)!=0) {
		screenray.pos.x.d = player.pos.x.d + player.rgt.x.d;
		screenray.pos.y.d = player.pos.y.d + player.rgt.y.d;
	}
	if ((player.movement&0b00001000)!=0) {
		screenray.pos.x.d = player.pos.x.d - player.rgt.x.d;
		screenray.pos.y.d = player.pos.y.d - player.rgt.y.d;
	}
	if ((player.movement&0b00010000)!=0) {
		player.angfwd += 1;
		player.angrgt += 1;
	}
	if ((player.movement&0b00100000)!=0) {
		player.angfwd -= 1;
		player.angrgt -= 1;
	}
	u = screenray.pos.x.u>>FPS;
	v = screenray.pos.y.u>>FPS;
	i = (v<<5)+u;
	m = TILEDROOM[i];
	if (m==0) {
		player.pos = screenray.pos;
	}
	player.movement = 0;
	player.loc.x.u = player.pos.x.u>>FPS;
	player.loc.y.u = player.pos.y.u>>FPS;
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

void drawvline(bool hit) {
	p = (screenray.pos.l.u>>FPS)>>2;
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
		c2 = m;
		if (m==1) {
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
	}
	q = l;
	switch(p) {
		case 12: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case 11: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case 10: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  9: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  8: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  7: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  6: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  5: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  4: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  3: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  2: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		case  1: TEXT_RAM[q] = v1; COLOR_RAM[q] = c1; q+=40;
		default:
		case  0: break;
	}
	switch(p) {
		case  0: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  1: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  2: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  3: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  4: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  5: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  6: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  7: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  8: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case  9: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case 10: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		case 11: TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40; TEXT_RAM[q] = v2; COLOR_RAM[q] = c2; q+=40;
		default:
		case 12: break;
	}
	switch(p) {
		case 12: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case 11: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case 10: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  9: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  8: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  7: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  6: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  5: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  4: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  3: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  2: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		case  1: TEXT_RAM[q] = v3; COLOR_RAM[q] = c3; q+=40;
		default:
		case  0: break;
	}
}

void main(void) {
	kbrepeat(KBREPEAT_ALL);
	joy_install(joy_static_stddrv);
	mouse_install(&mouse_def_callbacks, mouse_static_stddrv);

	bzero(TILEDROOM, TILEDSIZE);
	bzero(TILEDSDF, TILEDSIZE);
	bzero(RAYTABLE, RAYSIZE);
	bzero(TEXT_RAM, SCREENSIZE);
	bzero(SCREEN_RAM, SCREENSIZE);
	bzero(BITMAP_RAM, SCREENSIZE*8);
	k = loadfile("tiledroom", (unsigned)TILEDROOM);
	l = cbm_k_readst();
	printf("room: %x - %x: %u, %u, %u, %u\n",l,k,TILEDROOM[0],TILEDROOM[1],TILEDROOM[2],TILEDROOM[3]);
	k = loadfile("tiledsdf", (unsigned)TILEDSDF);
	l = cbm_k_readst();
	printf("sdf: %x - %x: %u, %u, %u, %u\n",l,k,TILEDSDF[0],TILEDSDF[1],TILEDSDF[2],TILEDSDF[3]);
	k = loadfile("tiledata", (unsigned)RAYTABLE);
	l = cbm_k_readst();
	printf("ray: %x - %x: %d, %d, %d, %d\n",l,k,RAYTABLE[0].x.d,RAYTABLE[0].y.d,RAYTABLE[1].x.d,RAYTABLE[1].y.d);
	k = loadfile("tiledata2", (unsigned)RAYTABLE2);
	l = cbm_k_readst();
	printf("ray2: %x - %x: %d, %d, %d, %d\n",l,k,RAYTABLE2[0].x.d,RAYTABLE2[0].y.d,RAYTABLE2[1].x.d,RAYTABLE2[1].y.d);
	k = loadfile("tileimage", (unsigned)IMAGE_RAM);
	l = cbm_k_readst();
	printf("image: %x - %x: %d, %d, %d, %d\n",l,k,IMAGE_RAM[0],IMAGE_RAM[1],IMAGE_RAM[2],IMAGE_RAM[3]);
	cputcxy(0,0,'a');
	cgetc();

	CIA1.cra = CIA1.cra&0xFE;
	CHARACTER_ROM_CONFIG[0] = CHARACTER_ROM_CONFIG[0]&0xFB;
	memcpy(CHARACTER_RAM, CHARACTER_ROM+0x800, CHARACTERSIZE);
	CHARACTER_ROM_CONFIG[0] = CHARACTER_ROM_CONFIG[0]|0x4;
	CIA1.cra = CIA1.cra|0x1;
	for (l=0;l<8;l+=2) {
		CHARACTER_RAM[744+l+0] = 0xaa;
		CHARACTER_RAM[744+l+1] = 0x55;
	}
	CIA2.pra = (CIA2.pra&0b11111100)|0b01;
	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00000000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	VIC.addr = 0b00100000;
	memset(COLOR_RAM, COLOR_WHITE, SCREENSIZE);
	memset(TEXT_RAM, 96, SCREENSIZE);
	COLOR_RAM[10*SCREENWIDTH+20] = COLOR_YELLOW;
	TEXT_RAM[10*SCREENWIDTH+20] = 91;
	COLOR_RAM[20*SCREENWIDTH+30] = COLOR_RED;
	TEXT_RAM[20*SCREENWIDTH+30] = 1;
	cgetc();

	clrscr();
	bordercolor(COLOR_BLACK);
	bgcolor(COLOR_GRAY1);
	textcolor(COLOR_WHITE);
	memset(SCREEN_RAM, 0xff, SCREENSIZE);
	SPRITE_RAM[0] = 48;
	SPRITE_RAM[1] = 49;
	SPRITE_RAM[2] = 50;
	SPRITE_RAM[3] = 51;
	SPRITE_RAM[4] = 52;
	SPRITE_RAM[5] = 53;
	SPRITE_RAM[6] = 54;
	SPRITE_RAM[7] = 55;
	VIC.spr0_x =  27; VIC.spr0_y =  36; VIC.spr0_color = COLOR_WHITE;
	VIC.spr1_x = 195; VIC.spr1_y =  67; VIC.spr1_color = COLOR_BLACK;
	VIC.spr2_x =   7; VIC.spr2_y = 121; VIC.spr2_color = COLOR_GREEN;
	VIC.spr3_x = 132; VIC.spr3_y =  57; VIC.spr3_color = COLOR_RED;
	VIC.spr4_x =  03; VIC.spr4_y =  10; VIC.spr4_color = COLOR_BLUE;
	VIC.spr5_x = 211; VIC.spr5_y =  47; VIC.spr5_color = COLOR_CYAN;
	VIC.spr6_x =  49; VIC.spr6_y = 141; VIC.spr6_color = COLOR_YELLOW;
	VIC.spr7_x =  45; VIC.spr7_y = 153; VIC.spr7_color = COLOR_GRAY2;
	VIC.spr_hi_x = 0b10010000;
	VIC.spr_exp_x = 0x00;
	VIC.spr_exp_y = 0xff;
	VIC.spr_bg_prio = 0b10101110;
	VIC.spr_ena = 0b00000000;
	while (!e) {
		time1 = gettime();
		handlekeyboard();
		handlemouse();
		handlejoystick();
		handlemovement();
		shufflestep+=5;
		if (shufflestep>=8) {
			shufflestep-=8;
		}
		k = player.indfwd + (SCREENWIDTH-1);
		for (l=shufflestep;l<SCREENWIDTH;l+=8) {
			screenray.pos = player.pos;
			screenray.dir = RAYTABLE[k-l];
			f = false;
			do {
				u = screenray.pos.x.u>>FPS;
				v = screenray.pos.y.u>>FPS;
				i = (v<<5)+u;
				m = TILEDROOM[i];
				if (m==0) {
					screenray.pos.x.d += screenray.dir.x.d;
					screenray.pos.y.d += screenray.dir.y.d;
					screenray.pos.l.u += screenray.dir.l.u;
				} else {
					f = true;
					COLUMN_ZBUFFER[l].l.u = screenray.pos.l.u;
					x = (screenray.pos.x.d<<4)&0b01110000;
					y = (screenray.pos.y.d<<4)&0b01110000;
					z = x;
					w = y;
					while(((z&0b10000000)==(x&0b10000000))&&((w&0b10000000)==(y&0b10000000))) {
						z = x;
						w = y;
						x -= screenray.dir.x.d;
						y -= screenray.dir.y.d;
					}
					COLUMN_ZBUFFER[l].x.d = z;
					COLUMN_ZBUFFER[l].y.d = w;
					x = z;
					y = w;
					if (z>63) {
						x = 127 - z;
					}
					if (w>63) {
						y = 127 - w;
					}
					if (x<y) {
						if (x<z) {
							COLUMN_ZBUFFER[l].a.d = 13;
						} else {
							COLUMN_ZBUFFER[l].a.d = -13;
						}
					} else {
						if (y<w) {
							COLUMN_ZBUFFER[l].a.d = -25;
						} else {
							COLUMN_ZBUFFER[l].a.d = 0;
						}
					}
					drawvline(true);
				}
			} while(!f);
		}
		time2 = gettime();
		timedif = time2 - time1;
		sprintf(ostr, "jcd: %d     ",timedif);
		cputsxy(30, 24, ostr);
		sprintf(ostr, "x,y: %u,%u  ",player.loc.x.u,player.loc.y.u);
		cputsxy(15, 24, ostr);
		memcpy(TEXT_RAM+960, DEFAULT_TEXT_RAM+960, 40);
	}
	cgetc();

	CIA2.pra = (CIA2.pra&0b11111100)|0b11;
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
	memcpy(SCREEN_RAM, IMAGE_RAM, SCREENSIZE);
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

	CIA2.pra = (CIA2.pra&0b11111100)|0b11;
	VIC.addr = 0b00010110;
	tgi_init();
	tgi_setpalette(tgipalette);
	cgetc();
	tgi_done();

	bgcolor(COLOR_BLUE);
	bordercolor(COLOR_LIGHTBLUE);
	textcolor(COLOR_LIGHTBLUE);
	printf("CZ:");
	for (l=0;l<SCREENWIDTH;l++) {
		printf("%u:%d#%d:%d, ",COLUMN_ZBUFFER[l].l.u,COLUMN_ZBUFFER[l].a.d,COLUMN_ZBUFFER[l].x.d,COLUMN_ZBUFFER[l].y.d);
	}
	printf("\n");
	printf("exit.\n");
}