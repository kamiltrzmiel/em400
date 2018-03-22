; OPTS -c configs/multix.cfg

	.cpu	mx16

	.include hw.inc
	.include io.inc
	.include mx.inc

	mcl
	uj	start

msk_mx:	.word	IMASK_CH0_1

	.org	OS_MEM_BEG

; ---------------------------------------------------------------
; wrong line types for winchester
; ---------------------------------------------------------------

dummy:	.word	0, 0 ; dummy to acknowledge IWYZE
tw0:	.word	1\7 + 1\15, 0
	.word	MX_LDIR_IN + MX_LINE_USED + MX_LTYPE_USARTS + 3
	.word	MX_LPROTO_WINCH + 2\15, 0, 0, 0 ; wrong line type for winchester
tw1:	.word	1\7 + 1\15, 0
	.word	MX_LDIR_IN + MX_LINE_USED + MX_LTYPE_USARTA + 3
	.word	MX_LPROTO_WINCH + 2\15, 0, 0, 0 ; wrong line type for winchester
tw2:	.word	1\7 + 1\15, 0
	.word	MX_LDIR_IN + MX_LINE_USED + MX_LTYPE_8255 + 3
	.word	MX_LPROTO_WINCH + 2\15, 0, 0, 0 ; wrong line type for winchester
tw3:	.word	1\7 + 1\15, 0
	.word	MX_LDIR_NONE + MX_LINE_USED + MX_LTYPE_FLOPPY + 3
	.word	MX_LPROTO_WINCH + 2\15, 0, 0, 0 ; wrong line type for winchester
tw4:	.word	1\7 + 1\15, 0
	.word	MX_LDIR_NONE + MX_LINE_USED + MX_LTYPE_TAPE + 3
	.word	MX_LPROTO_WINCH + 2\15, 0, 0, 0 ; wrong line type for winchester

	.const	test_size 3

seq:
	.word	dummy,	MX_IWYZE,	0
	.word	tw0,	MX_INKON,	MX_SCERR_TYPE_MISMATCH + 0
	.word	tw1,	MX_INKON,	MX_SCERR_TYPE_MISMATCH + 0
	.word	tw2,	MX_INKON,	MX_SCERR_TYPE_MISMATCH + 0
	.word	tw3,	MX_INKON,	MX_SCERR_TYPE_MISMATCH + 0
	.word	tw4,	MX_INKON,	MX_SCERR_TYPE_MISMATCH + 0
seqe:

; ------------------------------------------------------------------------
; expects:
;  r1 - configuration field address
;  r4 - RJ return adress
setcfg:
	ou	r1, MX_IO_SETCFG | MX_CHAN
	.word	no, en, ok, pe
no:	hlt	041
ok:	uj	r4
en:	ujs	setcfg
pe:	hlt	042

; ------------------------------------------------------------------------
mx_proc:
	lw	r1, [STACKP]
	lw	r1, [r1-1]	; intspec from mx

	cw	r1, [r2+1]	; is intspec as expected?
	bb	r0, ?E
	hlt	040		; bad intspec

	cw	r1, MX_INKOT	; skip setconf result if INKOT
	jes	next

	lw	r1, [r2+2]	; load expected setconf return value
	lw	r3, [r2]
	lw	r5, [r3+1]
	cw	r1, r5		; load setconf return value
	bb	r0, ?E
	hlt	043		; bad setconf result

next:
	awt	r2, test_size	; next test
	cw	r2, seqe	; all tests finished?
	blc	?E
	hlt	077		; all tests OK

	lw	r1, [r2]
	rj	r4, setcfg

	lip

; ------------------------------------------------------------------------
start:
	lw	r1, stack
	rw	r1, STACKP
	lw	r1, mx_proc
	rw	r1, MX_IV

	lw	r2, seq		; start of all tests
	im	msk_mx
loop:
	hlt
	ujs	loop

stack:

; XPCT rz[15] : 0
; XPCT rz[6] : 0
; XPCT alarm : 0
; XPCT ir : 0xec3f
