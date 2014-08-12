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

#include <string.h>
#include <assert.h>

#include "cpu/cpu.h"
#include "cpu/registers.h"
#include "cpu/interrupts.h"
#include "mem/mem.h"
#include "cpu/iset.h"
#include "cpu/instructions.h"
#include "cpu/interrupts.h"
#include "cpu/timer.h"

#include "em400.h"
#include "cfg.h"
#include "utils.h"
#include "errors.h"

#ifdef WITH_DEBUGGER
#include "debugger/debugger.h"
#include "debugger/ui.h"
#include "debugger/dasm.h"
#endif
#include "debugger/log.h"

int P;
uint32_t N;
int cpu_mod;

#ifdef WITH_DEBUGGER
uint16_t cycle_ic;
#endif

// -----------------------------------------------------------------------
// returns -1 on success
// anything >0 means that we've tried to overwrite that opcode
// (this cannot happen)
static int cpu_register_op(struct em400_op **op_tab, uint16_t opcode, uint16_t mask, struct em400_op *op, int overwrite_check)
{
	int i, pos;
	int offsets[16];
	int one_count = 0;
	int max;
	uint16_t result;

	if (!mask) return E_OK;

	for (i=0 ; i<16 ; i++) {
		if (mask & (1<<i)) {
			offsets[one_count] = i;
			one_count++;
		}
	}

	max = (1 << one_count) - 1;

	for (i=0 ; i<=max ; i++) {
		result = 0;
		for (pos=one_count-1 ; pos>=0 ; pos--) {
			result |= ((i >> pos) & 1) << offsets[pos];
		}
		if (overwrite_check && op->fun && op_tab[opcode|result]->fun) {
			return E_SLID_INIT;
		}
		op_tab[opcode | result] = op;
	}
	return E_OK;
}

// -----------------------------------------------------------------------
int cpu_init()
{
	int res;

	regs[R_KB] = em400_cfg.keys;

	// initialize instruction decoder
	cpu_register_op(em400_op_tab, 0, 0xffff, &em400_instr_illegal.op, 0);
	struct em400_instr *instr = em400_ilist_mera400;
	while (instr->var_mask) {
		res = cpu_register_op(em400_op_tab, instr->opcode, instr->var_mask, &instr->op, 1);
		if (res != E_OK) {
			return res;
		}
		instr++;
	}

	// register CRON instruction, if cpu mod is enabled in configuration
	if (em400_cfg.cpu_mod) {
		res = cpu_register_op(em400_op_tab, em400_instr_cron.opcode, em400_instr_cron.var_mask, &em400_instr_cron.op, 1);
		if (res != E_OK) {
			return res;
		}
	}

	// set IN/OU operations user-legalness
	if (!em400_cfg.cpu_user_io_illegal) {
		cpu_register_op(em400_op_tab, em400_instr_in_legal.opcode, em400_instr_in_legal.var_mask, &em400_instr_in_legal.op, 0);
		cpu_register_op(em400_op_tab, em400_instr_ou_legal.opcode, em400_instr_ou_legal.var_mask, &em400_instr_ou_legal.op, 0);
	}

	cpu_reset();

	// init interrupts
	if (sem_init(&int_ready, 0, 0)) {
		return E_SEM_INIT;
	}
	int_update_mask(regs[R_SR]);

	return E_OK;
}

// -----------------------------------------------------------------------
void cpu_shutdown()
{
	sem_destroy(&int_ready);
}

// -----------------------------------------------------------------------
int cpu_mod_on()
{
	// indicate that CPU modifications are preset
	cpu_mod = 1;

	// set interrupts as for modified CPU
	int_timer = INT_EXTRA;
	int_extra = INT_TIMER;

	// register SINT/SIND instructions
	cpu_register_op(em400_op_tab, em400_instr_sint.opcode, em400_instr_sint.var_mask, &em400_instr_sint.op, 0);
	cpu_register_op(em400_op_tab, em400_instr_sind.opcode, em400_instr_sind.var_mask, &em400_instr_sind.op, 0);

	return E_OK;
}

// -----------------------------------------------------------------------
int cpu_mod_off()
{
	// indicate that CPU modifications are absent
	cpu_mod = 0;

	// set interrupts as for vanilla CPU
	int_timer = INT_TIMER;
	int_extra = INT_EXTRA;

	// unregister SINT/SIND instructions (make them illegal)
	cpu_register_op(em400_op_tab, em400_instr_sint.opcode, em400_instr_sint.var_mask, &em400_instr_illegal.op, 0);
	cpu_register_op(em400_op_tab, em400_instr_sind.opcode, em400_instr_sind.var_mask, &em400_instr_illegal.op, 0);

	return E_OK;
}

// -----------------------------------------------------------------------
void cpu_reset()
{
	// disable cpu modifications
	cpu_mod_off();

	// clear registers
	for (int i=0 ; i<R_MAX ; i++) {
		regs[i] = 0;
	}

	// reset memory configuration
	mem_reset();

	// clear all interrupts
	int_clear_all();
}

// -----------------------------------------------------------------------
int cpu_ctx_switch(uint16_t arg, uint16_t ic, uint16_t sr_mask)
{
	uint16_t sp;
	if (!mem_cpu_get(0, 97, &sp)) return 0;
	if (!mem_cpu_put(0, sp, regs[R_IC])) return 0;
	if (!mem_cpu_put(0, sp+1, regs[0])) return 0;
	if (!mem_cpu_put(0, sp+2, regs[R_SR])) return 0;
	if (!mem_cpu_put(0, sp+3, arg)) return 0;
	if (!mem_cpu_put(0, 97, sp+4)) return 0;
	regs[0] = 0;
	regs[R_IC] = ic;
	regs[R_SR] &= sr_mask;
	int_update_mask();
	LOG(L_CPU, 20, "ctx switch: 0x%04x", ic);
	return 1;
}

// -----------------------------------------------------------------------
int cpu_ctx_restore()
{
	uint16_t data;
	uint16_t sp;

	if (!mem_cpu_get(0, 97, &sp)) return 0;
	if (!mem_cpu_get(0, sp-4, &data)) return 0;
	regs[R_IC] = data;
	LOG(L_CPU, 20, "ctx restore: 0x%04x", data);
	if (!mem_cpu_get(0, sp-3, &data)) return 0;
	regs[0] = data;
	if (!mem_cpu_get(0, sp-2, &data)) return 0;
	regs[R_SR] = data;
	int_update_mask();
	if (!mem_cpu_put(0, 97, sp-4)) return 0;
	return 1;
}

// -----------------------------------------------------------------------
void cpu_step()
{
	struct em400_op *op;
	uint16_t data;

#ifdef WITH_DEBUGGER
	cycle_ic = regs[R_IC];
#endif

	// fetch instruction
	if (!mem_cpu_get(QNB, regs[R_IC], regs+R_IR)) {
		regs[R_MODc] = regs[R_MOD] = 0;
		LOG(L_CPU, 10, "    (no mem)");
		return;
	}
	regs[R_IC]++;

	// find instruction
	op = em400_op_tab[regs[R_IR]];

	// end cycle if P is set
	if (P) {
		LOG(L_CPU, 10, "    (skip)");
		P = 0;
		// skip also M-arg if present
		if (op->norm_arg && !IR_C) {
			regs[R_IC]++;
		}
		return;
	}

	// end cycle if op is ineffective
	if (
	!op->fun
	|| (Q && op->user_illegal)
	|| ((regs[R_MODc] >= 3) && (op->fun == op_77_md))
	) {
#ifdef WITH_DEBUGGER
	char buf[256];
	dt_trans(cycle_ic, buf, DMODE_DASM);
	LOG(L_CPU, 10, "    (ineffective) %s Q: %d, MODc=%d (%s%s)", buf, Q, regs[R_MODc], op->fun?"legal":"illegal", op->user_illegal?"":", user illegal");
#endif
		regs[R_MODc] = regs[R_MOD] = 0;
		int_set(INT_ILLEGAL_OPCODE);
		// skip also M-arg if present
		if (op->norm_arg && !IR_C) {
			regs[R_IC]++;
		}
		return;
	}

	// process argument
	if (op->norm_arg) {
		if (IR_C) {
			N = (uint16_t) (regs[IR_C] + regs[R_MOD]);
		} else {
			if (!mem_cpu_get(QNB, regs[R_IC], &data)) goto catch_nomem;
			N = (uint16_t) (data + regs[R_MOD]);
			regs[R_IC]++;
		}
		if (IR_B) {
			N += regs[IR_B];
		}
		if (IR_D) {
			if (!mem_cpu_get(QNB, N, &data)) goto catch_nomem;
			N = data;
		}
	} else if (op->short_arg) {
		N = (uint16_t) IR_T + (uint16_t) regs[R_MOD];
	}

#ifdef WITH_DEBUGGER
	char buf[256];
	dt_trans(cycle_ic, buf, DMODE_DASM);
	char mbuf[64];
	if (regs[R_MODc]) {
		sprintf(mbuf, "MOD = 0x%04x = %6i", regs[R_MOD], regs[R_MOD]);
	} else {
		*mbuf = '\0';
	}
	if (op->norm_arg) {
		LOG(L_CPU, 10, "    %-20s N = 0x%04x = %i %s", buf, (uint16_t) N, (int16_t) N, mbuf);
	} else if (op->short_arg) {
		LOG(L_CPU, 10, "    %-20s T = %i  %s", buf, (int16_t) N, mbuf);
	} else {
		LOG(L_CPU, 10, "    %-20s", buf);
	}
#endif

	// execute instruction
	op->fun();

catch_nomem:
	// clear mod if instruction wasn't md
	if (op->fun != op_77_md) {
		regs[R_MODc] = regs[R_MOD] = 0;
	}
}

// vim: tabstop=4 shiftwidth=4 autoindent
