#include <c64.h>
#include <conio.h>
#include <stdio.h>
#include <stdlib.h>
#include <tgi.h>

unsigned char* SCREEN_RAM = (unsigned char*)0x400;
int i=0;

void main(void)
{
	bgcolor(COLOR_ORANGE);
	bordercolor(COLOR_CYAN);
	textcolor(COLOR_GREEN);
	clrscr();
	printf("Hello, world test!\n");
	cgetc();

	tgi_install(tgi_static_stddrv);
	tgi_init();
	tgi_clear();
	tgi_circle(160,100,20);
	cgetc();
	tgi_done();

	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00100000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	for (i=0;i<40*25;i++) {
		SCREEN_RAM[i] = 0;
		COLOR_RAM[i] = 0;
	}
	cgetc();

	VIC.ctrl1 = (VIC.ctrl1&0b10011111)|0b00000000;
	VIC.ctrl2 = (VIC.ctrl2&0b11101111)|0b00000000;
	for (i=0;i<40*25;i++) {
		SCREEN_RAM[i] = 96;
		COLOR_RAM[i] = (COLOR_LIGHTBLUE<<4) | COLOR_WHITE;
	}
	SCREEN_RAM[10*40+20] = 91;
	textcolor(COLOR_RED);
	cputcxy(30, 20, 'A');
	cgetc();
}