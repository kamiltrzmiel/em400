.program "op/JN"

	lw r1, 15
	cw r1, 15
	jn fin
	hlt 077
fin:	hlt 077


.endprog

; XPCT int(rz(6)) : 0
; XPCT int(sr) : 0

; XPCT int(ic) : 7

