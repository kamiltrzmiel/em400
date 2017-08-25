; OPTS -c configs/mod_mega_max.cfg

; test full 17-bit byte addressing across process address space on modified (MX-16) cpu with enabled modifications

	.cpu	mx16

	.include addr-skeleton.inc
	.include addr-fill-7.inc

; ------------------------------------------------------------------------
; ---- MAIN --------------------------------------------------------------
; ------------------------------------------------------------------------
start:
	cron

	lj	mem_cfg
	im	mask
	lj	fill_7
	lj	run_test

	hlt	077

; ------------------------------------------------------------------------
; test simple byte addressing
run_test:
	.res	1
	lw	r6, test_start

next_t:
	lw	r2, r6		; load original value
	mw	mul

	lw	r1, r2		; prepare original left byte
	shc	r1, 8
	nr	r1, 0x00ff

	lwt	r7, 0		; load left byte
	lb	r7, r6+r6

	cw	r1, r7		; check left byte
	bb	r0, ?E
	hlt	042

	lw	r1, r2		; prepare original right byte
	nr	r1, 0x00ff

	lwt	r7, 0		; load right byte
	md	1
	lb	r7, r6+r6

	cw	r1, r7		; check right byte
	bb	r0, ?E
	hlt	042

	; next word
	irb	r6, next_t

	uj	[run_test]

test_start:

; XPCT ir : 0xec3f
