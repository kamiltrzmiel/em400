
	.cpu	mera400

	lwt	r1, 0
	lwt	r2, 0
	lwt	r3, 0
	lwt	r4, 0
	lwt	r5, 0
	lwt	r6, 0
	lwt	r7, 0
	lf	data

	HLT	077

data:	.word	0xfafa, 0xbaba, 0xdada

; XPCT r1 : 0xfafa
; XPCT r2 : 0xbaba
; XPCT r3 : 0xdada
; XPCT r4 : 0
; XPCT r5 : 0
; XPCT r6 : 0
; XPCT r7 : 0
