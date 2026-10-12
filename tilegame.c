#include <c64.h>
#include <conio.h>
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

const unsigned char tgipalette[2] = {TGI_COLOR_BLACK, TGI_COLOR_LIGHTBLUE};

#define SCREENWIDTH 40
#define SCREENHEIGHT 25
#define SCREENSIZE 1000
#define TILEDDIM 64
#define TILEDSIZE 4096
#define RAYSIZE 512
#define FPS 8
#define SCREEN_RAM ((unsigned char*)0x0400)
#define BITMAP_RAM ((unsigned char*)0x2000)
#define TILEDROOM ((unsigned char*)0x4000)
#define RAYTABLE ((vec*)0x5000)

int i=0, j=0;
ray player = {0};
ray screenray = {0};

void main(void) {
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

	memset(TILEDROOM, 1, TILEDSIZE);
	memset(RAYTABLE, 2, RAYSIZE*4);

	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00100000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	VIC.addr = 0b00011000;
	memset(BITMAP_RAM, 0, SCREENSIZE*8);
	memset(SCREEN_RAM, 0, SCREENSIZE);
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
	for (i=0;i<RAYSIZE;i+=2) {
		screenray.pos.x = player.pos.x;
		screenray.pos.y = player.pos.y;
		screenray.dir.x = RAYTABLE[i].x;
		screenray.dir.y = RAYTABLE[i+1].x;
	}
	cgetc();

	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00000000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	VIC.addr = 0b00010100;
	memset(SCREEN_RAM, 96, SCREENSIZE);
	memset(COLOR_RAM, COLOR_WHITE, SCREENSIZE);
	COLOR_RAM[10*SCREENWIDTH+20] = COLOR_YELLOW;
	SCREEN_RAM[10*SCREENWIDTH+20] = 91;
	textcolor(COLOR_RED);
	cputcxy(30, 20, 'a');
	cgetc();

	clrscr();
	bgcolor(COLOR_BLUE);
	bordercolor(COLOR_LIGHTBLUE);
	textcolor(COLOR_LIGHTBLUE);
	printf("exit.\n");
}