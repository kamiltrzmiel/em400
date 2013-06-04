%{
//  Copyright (c) 2012-2013 Jakub Filipowicz <jakubf@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

#include <stdlib.h>
#include <stdio.h>
#include <stdarg.h>

#include "cfg.h"
#include "io/drivers.h"

int this_chan;

void cyyerror(char *s, ...);
int cyylex(void);
%}

%locations
%union {
	struct value_t {
		int v;
		char *s;
	} value;
	struct cfg_arg_t *arg;
};

%token CPU MEMORY CHANNEL UNIT
%token SPEED MAX REAL TIMER MOD_17 MOD_SINT
%token MODULE ELWRO MEGA OS_SEG
%token <value> TEXT
%token <value> VALUE
%type <arg> arg arglist

%token '{' '}' '=' ':' ','

%%

objects:
	objects object
	|
	;

object:
	CPU '{' cpu_opts '}'
	| MEMORY '{' os_mem modules '}'
	| CHANNEL VALUE { this_chan=$2.v; } '=' TEXT '{' units '}' { cfg_make_chan($2.v, $5.s); free($2.s); }
	;

units:
	unit units
	|
	;

unit:
	UNIT VALUE '=' TEXT ':' arglist	{ cfg_make_unit(this_chan, $2.v, $4.s, $6); free($2.s); }
	| UNIT VALUE '=' TEXT			{ cfg_make_unit(this_chan, $2.v, $4.s, NULL); free($2.s); }
	;

arglist:
	arg ',' arglist	{ $1->next = $3; $$ = $1; }
	| arg			{ $$ = $1; }
	;

arg:
	VALUE	{ $$ = cfg_make_arg($1.s); }
	| TEXT	{ $$ = cfg_make_arg($1.s); }
	;

cpu_opts:
	cpu_opts cpu_opt
	|
	;

cpu_opt:
	SPEED '=' MAX			{ em400_cfg.cpu.speed_real = 0; }
	| SPEED '=' REAL		{ em400_cfg.cpu.speed_real = 1; }
	| TIMER '=' VALUE		{ em400_cfg.cpu.timer_step = $3.v; free($3.s); }
	| MOD_17 '=' VALUE		{ em400_cfg.cpu.mod_17bit = $3.v; free($3.s); }
	| MOD_SINT '=' VALUE	{ em400_cfg.cpu.mod_sint = $3.v; free($3.s); }
	;

modules:
	modules module
	| module
	;

module:
	MODULE VALUE '=' ELWRO ':' VALUE	{ cfg_set_mem($2.v, 0, $6.v); free($2.s); free($6.s); }
	| MODULE VALUE '=' MEGA ':' VALUE	{ cfg_set_mem($2.v, 1, $6.v); free($2.s); free($6.s); }
	;

os_mem:
	OS_SEG '=' VALUE { cfg_set_os_mem($3.v); free($3.s); }
	;
%%

// -----------------------------------------------------------------------
void cyyerror(char *s, ...)
{
	va_list ap;
	va_start(ap, s);
	printf("Error parsing config, line %d: ", yylloc.first_line);
	vprintf(s, ap);
	printf("\n");
	cfg_error = 1;
}

// vim: tabstop=4 shiftwidth=4 autoindent
