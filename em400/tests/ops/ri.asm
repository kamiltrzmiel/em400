.program "op/RI"

; PRE r1 = 10

	ri r1, 15

	hlt 077

.endprog

; XPCT int(rz(6)) : 0
; XPCT int(sr) : 0

; XPCT int(r1) : 11
; XPCT int([10]) : 15
; XPCT int([11]) : 0

