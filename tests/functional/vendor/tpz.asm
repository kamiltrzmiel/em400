; OPTS -c configs/minimal.ini
;
; MERA-400 floating point unit "TPZ" test.
;
; Based on the original test provided by the manufacturer.
; The only difference is that this version uses changed HLT codes.

	.include cpu.inc

	; use EM400 compatibile hlt codes if running in an emulator
	.ifdef	EM400
	.const	ERR_CODE 040
	.else
	.const	ERR_CODE 0
	.endif

	ujs	init

; ------------------------------------------------------------------------
timerx:
ch1x:
ch3x:	lip

; ------------------------------------------------------------------------
init:	mcl
	lw	r1, stack
	rw	r1, stackp
	im	mask
	uj	test_ad

; ------------------------------------------------------------------------
mask:	.word	IMASK_ALL
status:	.word	0

; ------------------------------------------------------------------------
fxp_ofx:lwt	r5, 0
	ujs	fpint
fp_ufx:	lw	r5, 0x20
	ujs	fpint
fp_ofx:	lw	r5, 0x40
	ujs	fpint
div0x:	lw	r5, 0x60

; ------------------------------------------------------------------------
fpint:	lw	r6, [stackp]
	awt	r6, -4
	lw	r0, [r6+1]
	jxs	f1
	ujs	f2
f1:	lw	r7, 0x60
	bs	r0, r5
	ujs	f3
fret:	lw	r7, [r6]
	lw	r0, [r6+1]
	rw	r6, stackp
	im	mask
	uj	r7+1
f2:	lws	r7, status
	cwt	r7, 0
	jes	fphlt1
	hlt	ERR_CODE
	ujs	fret
fphlt1:	hlt	ERR_CODE
	ujs	fret
f3:	lws	r7, status
	cwt	r7, 0
	jes	fphlt2
	hlt	ERR_CODE
	ujs	fret
fphlt2:	hlt	ERR_CODE
	ujs	fret

; ------------------------------------------------------------------------
	.org 0x40

	.word	powerx
	.word	parx
	.word	nomemx
	.word	c2hix
	.word	ifpwrx
	.word	timerx
	.word	opx
	.word	fxp_ofx
	.word	fp_ufx
	.word	fp_ofx
	.word	div0x
	.word	extrax
	.word	ch0x
	.word	ch1x
	.word	ch2x
	.word	ch3x
	.word	ch4x
	.word	ch5x
	.word	ch6x
	.word	ch7x
	.word	ch8x
	.word	ch9x
	.word	ch10x
	.word	ch11x
	.word	ch12x
	.word	ch13x
	.word	ch14x
	.word	ch15x
	.word	oprqx
	.word	c2lox
	.word	softhx
	.word	softlx

; ------------------------------------------------------------------------
exlp:	.word	exlx
stackp:	.word	stack
stack:	.res	8

; ------------------------------------------------------------------------
exlx:	awt	r0, 1
softlx:	awt	r0, 1
softhx:	awt	r0, 1
c2lox:	awt	r0, 1
oprqx:	awt	r0, 1
ch15x:	awt	r0, 1
ch14x:	awt	r0, 1
ch13x:	awt	r0, 1
ch12x:	awt	r0, 1
ch11x:	awt	r0, 1
ch10x:	awt	r0, 1
ch9x:	awt	r0, 1
ch8x:	awt	r0, 1
ch7x:	awt	r0, 1
ch6x:	awt	r0, 1
ch5x:	awt	r0, 1
ch4x:	awt	r0, 1
	awt	r0, 1
ch2x:	awt	r0, 1
	awt	r0, 1
ch0x:	awt	r0, 1
extrax:	awt	r0, 1
	awt	r0, 4
opx:	awt	r0, 1
	awt	r0, 1
ifpwrx:	awt	r0, 1
c2hix:	awt	r0, 1
nomemx:	awt	r0, 1
parx:	awt	r0, 1
powerx:	lws	r3, stackp
	ld	r3-4
	hlt	ERR_CODE
	uj	init

; ------------------------------------------------------------------------
test_ad:
	rz	status
	lw	r4, data_ad
loop1:	lw	r0, [r4]
	ld	r4+2
	ad	r4+4
	jxs	halt1
jmp1:	lj	check_
	cw	r4, data_sd
	jes	test_sd
	ujs	loop1
halt1:	hlt	ERR_CODE
	ujs	jmp1

; ------------------------------------------------------------------------
test_sd:
	lw	r4, data_sd
loop2:	lw	r0, [r4]
	ld	r4+2
	sd	r4+4
	jxs	halt2
jmp2:	lj	check_
	cw	r4, data_mw
	jes	test_mw
	ujs	loop2
halt2:	hlt	ERR_CODE
	ujs	jmp2

; ------------------------------------------------------------------------
check_:	.res	1
check:
	rws	r0, tmp
	lw	r5, [r4+1]
	lw	r7, 0xf000
	bs	r0, r5
	ujs	chk
load:	ll	r4+6
	cw	r1, r5
	jes	chok
	ujs	chhlt3
chok:	cw	r2, r6
	jes	chexi
	ujs	chhlt3

chexi:	awt	r4, 8
	uj	[check_]

chk:	lws	r0, tmp
	brc	2
	ujs	chhlt1
	hlt	ERR_CODE
	ujs	load
chhlt1:	hlt	ERR_CODE
	ujs	load
chhlt3:	lws	r0, tmp
	brc	2
	ujs	chhlt2
	hlt	ERR_CODE
	ujs	chexi
chhlt2:	hlt	ERR_CODE
	ujs	chexi
tmp:	.res	1

; ------------------------------------------------------------------------
test_mw:
	lw	r4, data_mw
loop3:	lw	r0, [r4]
	lw	r2, [r4+2]
	mw	r4+3
	jxs	halt3
jmp3:	rws	r0, tmp
	lw	r5, [r4+1]
	lw	r7, 0xf000
	bs	r0, r5
	ujs	gdzies
load3:	ll	r4+4
	cw	r1, r5
	jes	ok3a
	ujs	exi3
ok3a:	cw	r2, r6
	jes	ok3b
	ujs	exi3
ok3b:	awt	r4, 6
	cw	r4, data_dw
	jes	test_dw
	ujs	loop3
halt3:	hlt	ERR_CODE
	ujs	jmp3
gdzies:	lws	r0, tmp
	hlt	ERR_CODE
	ujs	load3
exi3:	lws	r0, tmp
	hlt	ERR_CODE
	ujs	ok3b

; ------------------------------------------------------------------------
test_dw:
	lw	r4, data_dw
loop4:	lw	r0, [r4]
	ld	r4+2
	dw	r4+4
	jxs	halt4
jmp4:	rws	r0, tmp
	lw	r5, [r4+1]
	lw	r7, 0xf000
	bs	r0, r5
	ujs	exi4c
load4:	ll	r4+5
	cw	r5, r2
	jes	ok4a
	ujs	exi4a
ok4a:	cw	r6, r1
	jes	ok4b
	ujs	exi4b
ok4b:	awt	r4, 7
	cw	r4, data_af
	jes	test_af
	ujs	loop4
halt4:	hlt	ERR_CODE
	ujs	jmp4
exi4c:	lw	r0, [tmp]
	hlt	ERR_CODE
	ujs	load4
exi4a:	lw	r0, [tmp]
	hlt	ERR_CODE
	ujs	ok4a
exi4b:	lw	r0, [tmp]
	hlt	ERR_CODE
	ujs	ok4b

; ------------------------------------------------------------------------
test_af:
	ib	status
	lw	r4, data_af
loop5:	lw	r0, [r4]
	lf	r4+2
	af	r4+5
	jxs	hlt5
load5:	lj	fchk_
	cw	r4, data_sf
	jes	test_sf
	ujs	loop5
hlt5:	hlt	ERR_CODE
	ujs	load5

; ------------------------------------------------------------------------
test_sf:
	lw	r4, data_sf
loop6:	lw	r0, [r4]
	lf	r4+2
	sf	r4+5
	jxs	halt6
load6:	lj	fchk_
	cw	r4, data_mf
	jes	test_mf
	ujs	loop6
halt6:	hlt	ERR_CODE
	ujs	load6

; ------------------------------------------------------------------------
test_mf:
	lw	r4, data_mf
loop7:
	lw	r0, [r4]
	lf	r4+2
	mf	r4+5
	jxs	halt7
load7:	lj	fchk_
	cw	r4, data_df
	jes	test_df
	ujs	loop7
halt7:	hlt	ERR_CODE
	ujs	load7

; ------------------------------------------------------------------------
test_df:
	lw	r4, data_df
loop8:
	lw	r0, [r4]
	lf	r4+2
	df	r4+5
	jxs	halt8
load8:	lj	fchk_
	cw	r4, data_nrf
	jes	test_nrf
	ujs	loop8
halt8:	hlt	ERR_CODE
	ujs	load8

; ------------------------------------------------------------------------
fchk_:	.res	1
fchk:	rws	r0, ftmp
	lw	r5, [r4+1]
	lw	r7, 0xf000
	bs	r0, r5
	ujs	fhlt1
fload:	ll	r4+8
	cw	r1, r5
	jes	fok1
	ujs	fhlt2
fok1:	cw	r2, r6
	jes	fok2
	ujs	fhlt2
fok2:	cw	r3, r7
	jes	fretch
	ujs	fhlt2
fretch: awt	r4, 11
	uj	[fchk_]
fhlt1:	lws	r0, ftmp
	hlt	ERR_CODE
	ujs	fload
fhlt2:	lws	r0, ftmp
	hlt	ERR_CODE
	ujs	fretch
ftmp:	.res	1

; ------------------------------------------------------------------------
test_nrf:
	lw	r4, data_nrf
loop9:
	lw	r0, [r4]
	lf	r4+2
	nrf	192
	jxs	hlt9a
jmp9:	rws	r0, ftmp
	lw	r5, [r4+1]
	lw	r7, 0xf000
	bs	r0, r5
	ujs	hlt9b
load9:	ll	r4+5
	cw	r1, r5
	jes	ok9a
	ujs	hlt9c
ok9a:	cw	r2, r6
	jes	ok9b
	ujs	hlt9c
ok9b:	cw	r3, r7
	jes	ok9c
	ujs	hlt9c
ok9c:	awt	r4, 8
	cw	r4, data_fin
	.ifdef  EM400 ; finish and indicate no error if running in EM400 emulator
	hlt	077
	.res	1 ; padding for consistent addressing
	.else ; loop over if running on a real hardware
	je	test_ad
	.endif
	ujs	loop9
hlt9a:	hlt	ERR_CODE
	ujs	jmp9
hlt9b:	lws	r0, ftmp
	hlt	ERR_CODE
	ujs	load9
hlt9c:	lws	r0, ftmp
	hlt	ERR_CODE
	ujs	ok9c

; ------------------------------------------------------------------------
data_ad:
;	r0 pre  r0 want a1      a2      b1      b2      w1      w2

; 0x1a5
.word	0x4201, 0x9201, 0x0000, 0x7fff, 0xffff, 0x8001, 0x0000, 0x0000
; 0100 = M
;   0000000000000000 0111111111111111
;   1111111111111111 1000000000000001
; 1 0000000000000000 0000000000000000
; 1001 = ZC

; 0x1ad
.word	0x9201, 0x5201, 0xffff, 0xffff, 0xffff, 0xffff, 0xffff, 0xfffe
; 1001 = ZC
;   1111111111111111 1111111111111111
;   1111111111111111 1111111111111111
; 1 1111111111111111 1111111111111110
; 0101 = MC

; 0x1b5
.word	0x5201, 0x0201, 0x0000, 0x8000, 0x0000, 0x8000, 0x0001, 0x0000
; 0101 = MC
;   0000000000000000 1000000000000000
;   0000000000000000 1000000000000000
;   0000000000000001 0000000000000000
; 0000 = .

; 0x1bd
.word	0x9201, 0x2201, 0x4000, 0x0000, 0x4000, 0x0000, 0x8000, 0x0000
; 1001 = ZC
;   0100000000000000 0000000000000000
;   0100000000000000 0000000000000000
;   1000000000000000 0000000000000000
; 0010 = V

; 0x1c5
.word	0x9201, 0x5201, 0x8000, 0x0001, 0xffff, 0xffff, 0x8000, 0x0000
; 1001 = ZC
;   1000000000000000 0000000000000001
;   1111111111111111 1111111111111111
; 1 1000000000000000 0000000000000000
; 0101 = MC

; 0x1cd
.word	0x2201, 0xb201, 0xffff, 0xffff, 0x0000, 0x0001, 0x0000, 0x0000
; 0010 = V
;   1111111111111111 1111111111111111
;   0000000000000000 0000000000000001
; 1 0000000000000000 0000000000000000
; 1011 = ZVC

; 0x1d5
.word	0x0201, 0x9201, 0xffff, 0x8000, 0x0000, 0x8000, 0x0000, 0x0000
; 0000 = .
;   1111111111111111 1000000000000000
;   0000000000000000 1000000000000000
; 1 0000000000000000 0000000000000000
; 1001 = ZC

; ------------------------------------------------------------------------
data_sd:
;	r0 pre  r0 want a1      a2      b1      b2      w1      w2
; 0x1dd
.word	0x4202, 0x4202, 0x0000, 0x7fff, 0x0000, 0x8000, 0xffff, 0xffff
; 0x1e5
.word	0x4202, 0x5202, 0xffff, 0xffff, 0x0000, 0x0001, 0xffff, 0xfffe
; 0x1ed
.word	0x5202, 0x0202, 0x0000, 0x8000, 0xffff, 0x8000, 0x0001, 0x0000
; 0x1f5
.word	0x0202, 0x9202, 0x0000, 0x8000, 0x0000, 0x8000, 0x0000, 0x0000
; 0x1fd
.word	0x0002, 0x2002, 0x4000, 0x0000, 0xbfff, 0xffff, 0x8000, 0x0001
; 0x205
.word	0x2002, 0xb002, 0xffff, 0xffff, 0xffff, 0xffff, 0x0000, 0x0000

; ------------------------------------------------------------------------
data_mw:
;	r0 pre  r0 want a1      b1      w1      w2
; 0x20d
.word	0x4204, 0x8204, 0x4000, 0x0000, 0x0000, 0x0000
; 0x213
.word	0x8204, 0x4204, 0x0001, 0xffff, 0xffff, 0xffff
; 0x219
.word	0x4204, 0x0204, 0x4000, 0x4000, 0x1000, 0x0000
; 0x21f
.word	0x0204, 0x0204, 0x8000, 0x8000, 0x4000, 0x0000
; 0x225
.word	0x0204, 0x4204, 0x0020, 0xffe0, 0xffff, 0xfc00
; 0x22b
.word	0x4204, 0x8204, 0x0000, 0x8000, 0x0000, 0x0000

; ------------------------------------------------------------------------
data_dw:
;	r0 pre  r0 want a1      a2      b1      wynik   reszta
; 0x231
.word	0x4008, 0x8008, 0x0000, 0x0000, 0x0800, 0x0000, 0x0000
; 0x238
.word	0x8008, 0x4008, 0x4000, 0x0000, 0x8000, 0x8000, 0x0000
; 0x23f
.word	0x0008, 0x4008, 0xffff, 0xfc00, 0x0020, 0xffe0, 0x0000
; 0x246
.word	0x4208, 0x8208, 0x0000, 0x0001, 0x0002, 0x0000, 0x0001
; 0x24d
.word	0x40e8, 0x40e8, 0x0000, 0x0002, 0x0000, 0x0002, 0x0000
; 0x254
.word	0x40e8, 0x40e8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x25b
.word	0x4088, 0x4088, 0x8000, 0x0000, 0x0010, 0x0000, 0x8000
; 0x262
.word	0x0088, 0x0088, 0x7fff, 0xffff, 0x0100, 0xffff, 0x7fff

; ------------------------------------------------------------------------
data_af:
;	r0 pre  r0 want a1      a2      a3      b1      b2      b3      w1      w2      w3
; 0x269
.word	0x42e1, 0x42e1, 0x6666, 0x3333, 0x3301, 0x1666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x274
.word	0x42e1, 0x42e1, 0x1666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x1666, 0x3333, 0x3301
; 0x27f
.word	0x4201, 0x8201, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x28a
.word	0x8201, 0x0201, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301
; 0x295
.word	0x0201, 0x0201, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x2a0
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3302
; 0x2ab
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3300, 0x4ccc, 0xa666, 0x6602
; 0x2b6
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f
; 0x2c1
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x33bf, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x2cc
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x33f0, 0x6666, 0x3333, 0x33f7, 0x6732, 0xff99, 0x99f7
; 0x2d7
.word	0x0201, 0x4201, 0x8000, 0x0000, 0x0000, 0x8000, 0x0000, 0x0000, 0x8000, 0x0000, 0x0001
; 0x2e2
.word	0x4201, 0x0201, 0x4000, 0x0000, 0x0002, 0x8000, 0x0000, 0x00ff, 0x6000, 0x0000, 0x0001
; 0x2ed
.word	0x0201, 0x8201, 0x4000, 0x0000, 0x0003, 0x8000, 0x0000, 0x0002, 0x0000, 0x0000, 0x0000
; 0x2f8
.word	0x8201, 0x0201, 0x4000, 0x0000, 0x0000, 0x6000, 0x0000, 0x0000, 0x5000, 0x0000, 0x0001
; 0x303
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x337f
; 0x30e
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x33f7, 0x6666, 0x3333, 0x33f0, 0x6732, 0xff99, 0x99f7
; 0x319
.word	0x0201, 0x0201, 0x0000, 0x0000, 0x0013, 0x6666, 0x3333, 0x3300, 0x6666, 0x3333, 0x3300
; 0x324
.word	0x0201, 0x0201, 0x6666, 0x3333, 0x3300, 0x0000, 0x0000, 0x0013, 0x6666, 0x3333, 0x3300
; 0x32f
.word	0x02c1, 0x02c1, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x337e, 0x4ccc, 0xa666, 0x6680
; 0x33a
.word	0x0201, 0x0201, 0x4666, 0x3333, 0x3381, 0x6666, 0x3333, 0x3382, 0x44cc, 0xa666, 0x6683
; 0x345
.word	0x0201, 0x0201, 0x6000, 0x0000, 0x0078, 0x4000, 0x0000, 0x0008, 0x6000, 0x0000, 0x0078
; 0x350
.word	0x0201, 0x0201, 0x7fff, 0xffff, 0xff04, 0x4000, 0x0000, 0x0005, 0x4000, 0x0000, 0x0006

; ------------------------------------------------------------------------
data_sf:
;	r0 pre  r0 want a1      a2      a3      b1      b2      b3      w1      w2      w3
; 0x35b
.word	0x42e2, 0x42e2, 0x6666, 0x3333, 0x3301, 0x3266, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x366
.word	0x42e2, 0x42e2, 0x1666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x1666, 0x3333, 0x3301
; 0x371
.word	0x4202, 0x8202, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x37c
.word	0x8202, 0x0202, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301
; 0x387
.word	0x0202, 0x4202, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301, 0x9999, 0xcccc, 0xcd01
; 0x392
.word	0x4202, 0x8202, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000
; 0x39d
.word	0x8202, 0x0202, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3300, 0x6666, 0x3333, 0x3300
; 0x3a8
.word	0x0202, 0x0202, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f
; 0x3b3
.word	0x0202, 0x4202, 0x6666, 0x3333, 0x33bf, 0x6666, 0x3333, 0x3301, 0x9999, 0xcccc, 0xcd01
; 0x3be
.word	0x4202, 0x4202, 0x6666, 0x3333, 0x33f0, 0x6666, 0x3333, 0x33f7, 0x9a66, 0x9933, 0x33f7
; 0x3c9
.word	0x4202, 0x8202, 0x8000, 0x0000, 0x0000, 0x8000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x3d4
.word	0x8202, 0x0202, 0x4000, 0x0000, 0x0002, 0x8000, 0x0000, 0x00ff, 0x5000, 0x0000, 0x0002
; 0x3df
.word	0x0202, 0x0202, 0x4000, 0x0000, 0x0003, 0x8000, 0x0000, 0x0002, 0x4000, 0x0000, 0x0004
; 0x3ea
.word	0x0202, 0x4202, 0x4000, 0x0000, 0x0000, 0x6000, 0x0000, 0x0000, 0x8000, 0x0000, 0x00fe
; 0x3f5
.word	0x4202, 0x4202, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f, 0x9999, 0xcccc, 0xcd7f
; 0x400
.word	0x4202, 0x1202, 0x6666, 0x3333, 0x33f7, 0x6666, 0x3333, 0x33f0, 0x6599, 0x66cc, 0xcdf7
; 0x40b
.word	0x0202, 0x4202, 0x0000, 0x0000, 0x0013, 0x6666, 0x3333, 0x3300, 0x9999, 0xcccc, 0xcd00
; 0x416
.word	0x4202, 0x0202, 0x6666, 0x3333, 0x3300, 0x0000, 0x0000, 0x0013, 0x6666, 0x3333, 0x3300
; 0x421
.word	0x0202, 0x0202, 0x6000, 0x0000, 0x0000, 0x4000, 0x0000, 0x0000, 0x4000, 0x0000, 0x00ff
; 0x42c
.word	0x0202, 0x0202, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x337e, 0x6666, 0x3333, 0x337e
; 0x437
.word	0x0202, 0x0202, 0x6000, 0x0000, 0x0078, 0x4000, 0x0000, 0x0008, 0x6000, 0x0000, 0x0078
; 0x442
.word	0x0202, 0x4202, 0x7fff, 0xffff, 0xff04, 0x4000, 0x0000, 0x0005, 0x8000, 0x0000, 0x00dd

; ------------------------------------------------------------------------
data_mf:
;	r0 pre  r0 want a1      a2      a3      b1      b2      b3      w1      w2      w3
; 0x44d
.word	0x42e4, 0x42e4, 0x6666, 0x3333, 0x3301, 0x1666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x458
.word	0x4204, 0x8204, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x463
.word	0x8204, 0x8204, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x46e
.word	0x8204, 0x8204, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000
; 0x479
.word	0x0204, 0x0204, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x51eb, 0x3333, 0x4702
; 0x484
.word	0x0204, 0x0204, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3300, 0x51eb, 0x3333, 0x4701
; 0x48f
.word	0x02c4, 0x02c4, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x3301, 0x51eb, 0x3333, 0x4780
; 0x49a
.word	0x0204, 0x0204, 0x6666, 0x3333, 0x33bf, 0x6666, 0x3333, 0x3301, 0x51eb, 0x3333, 0x47c0
; 0x4a5
.word	0x0204, 0x0204, 0x6666, 0x3333, 0x33f0, 0x6666, 0x3333, 0x33f7, 0x51eb, 0x3333, 0x47e7
; 0x4b0
.word	0x8204, 0x0204, 0x8000, 0x0000, 0x0000, 0x8000, 0x0000, 0x0000, 0x4000, 0x0000, 0x0001
; 0x4bb
.word	0x0204, 0x4204, 0x4000, 0x0000, 0x0002, 0x8000, 0x0000, 0x00ff, 0x8000, 0x0000, 0x0000
; 0x4c6
.word	0x4204, 0x4204, 0x4000, 0x0000, 0x0003, 0x8000, 0x0000, 0x0002, 0x8000, 0x0000, 0x0004
; 0x4d1
.word	0x4204, 0x0204, 0x4000, 0x0000, 0x0000, 0x6000, 0x0000, 0x0000, 0x6000, 0x0000, 0x00ff
; 0x4dc
.word	0x02c4, 0x02c4, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f, 0x51eb, 0x3333, 0x4780
; 0x4e7
.word	0x0204, 0x8204, 0x0000, 0x0000, 0x0013, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000
; 0x4f2
.word	0x02c4, 0x02c4, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x337e, 0x51eb, 0x3333, 0x47fd
; 0x4fd
.word	0x02a4, 0x02a4, 0x4666, 0x3333, 0x3381, 0x6666, 0x3333, 0x3382, 0x70a3, 0x4ccc, 0xf502
; 0x508
.word	0x0204, 0x0204, 0x6000, 0x0000, 0x0078, 0x4000, 0x0000, 0x0008, 0x6000, 0x0000, 0x007f
; 0x513
.word	0x0204, 0x0204, 0x7fff, 0xffff, 0xff04, 0x4000, 0x0000, 0x0005, 0x7fff, 0xffff, 0xff08

; ------------------------------------------------------------------------
data_df:
;	r0 pre  r0 want a1      a2      a3      b1      b2      b3      w1      w2      w3
; 0x51e
.word	0x10e8, 0x10e8, 0x6666, 0x3333, 0x3301, 0x1666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301
; 0x529
.word	0x02e8, 0x02e8, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x534
.word	0x02e8, 0x02e8, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301
; 0x53f
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3301, 0x4000, 0x0000, 0x0001
; 0x54a
.word	0x4208, 0x8208, 0x0000, 0x0000, 0x0000, 0x6666, 0x3333, 0x3301, 0x0000, 0x0000, 0x0000
; 0x555
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x3300, 0x4000, 0x0000, 0x0002
; 0x560
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x3301, 0x4000, 0x0000, 0x007f
; 0x56b
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x33bf, 0x6666, 0x3333, 0x3301, 0x4000, 0x0000, 0x00bf
; 0x576
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x33f0, 0x6666, 0x3333, 0x33f7, 0x4000, 0x0000, 0x00fa
; 0x581
.word	0x0208, 0x0208, 0x8000, 0x0000, 0x0000, 0x8000, 0x0000, 0x0000, 0x4000, 0x0000, 0x0001
; 0x58c
.word	0x0208, 0x4208, 0x4000, 0x0000, 0x0002, 0x8000, 0x0000, 0x00ff, 0x8000, 0x0000, 0x0002
; 0x597
.word	0x8208, 0x4208, 0x4000, 0x0000, 0x0003, 0x8000, 0x0000, 0x0002, 0x8000, 0x0000, 0x0000
; 0x5a2
.word	0x4208, 0x0208, 0x4000, 0x0000, 0x0000, 0x6000, 0x0000, 0x0000, 0x5555, 0x5555, 0x5500
; 0x5ad
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x3301, 0x6666, 0x3333, 0x337f, 0x4000, 0x0000, 0x0083
; 0x5b8
.word	0x0208, 0x0208, 0x6666, 0x3333, 0x33f7, 0x6666, 0x3333, 0x33f0, 0x4000, 0x0000, 0x0008
; 0x5c3
.word	0x0208, 0x8201, 0x0000, 0x0000, 0x0013, 0x4000, 0x0000, 0x0000, 0x0000, 0x0000, 0x0000
; 0x5ce
.word	0x8208, 0x0208, 0x6666, 0x3333, 0x337f, 0x6666, 0x3333, 0x337e, 0x4000, 0x0000, 0x0002
; 0x5d9
.word	0x0208, 0x0208, 0x4666, 0x3333, 0x3381, 0x6666, 0x3333, 0x3382, 0x57ff, 0xebff, 0xf5ff
; 0x5e4
.word	0x0208, 0x0208, 0x6000, 0x0000, 0x0078, 0x4000, 0x0000, 0x0008, 0x6000, 0x0000, 0x0071
; 0x5ef
.word	0x0208, 0x0208, 0x7fff, 0xffff, 0xff04, 0x4000, 0x0000, 0x0005, 0x7fff, 0xffff, 0xff00

; ------------------------------------------------------------------------
data_nrf:
;	r0 pre  r0 want a1      a2      a3      w1      w2      w3
; 0x5fa
.word	0x4010, 0x0010, 0x0013, 0x0000, 0x0000, 0x4c00, 0x0000, 0x00f6
; 0x602
.word	0x0010, 0x0010, 0x0008, 0x0000, 0x0000, 0x4000, 0x0000, 0x00f5
; 0x60a
.word	0x0010, 0x8010, 0x0000, 0x0000, 0x00bf, 0x0000, 0x0000, 0x0000
; 0x612
.word	0x00b0, 0x40b0, 0xf000, 0x001f, 0x0080, 0x8000, 0x00f8, 0x007d
; 0x61a
.word	0x0010, 0x4010, 0xffff, 0x0000, 0x0000, 0x8000, 0x0000, 0x00f1

; ------------------------------------------------------------------------
data_fin:
; 0x622

; XPCT ir : 0xec3f
