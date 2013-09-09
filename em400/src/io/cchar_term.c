//  Copyright (c) 2013 Jakub Filipowicz <jakubf@gmail.com>
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
#include <string.h>
#include <inttypes.h>
#include <stdio.h>

#include "debugger/log.h"
#include "errors.h"
#include "cpu/memory.h"
#include "io/cchar.h"
#include "io/cchar_term.h"
#include "io/term.h"

#define UNIT ((struct cchar_unit_term_t *)(unit))

// -----------------------------------------------------------------------
struct cchar_unit_proto_t * cchar_term_create(struct cfg_arg_t *args)
{
	struct cchar_unit_term_t *unit = calloc(1, sizeof(struct cchar_unit_term_t));
	if (!unit) {
		goto fail;
	}

	unit->term = term_open_tcp(32000, 100);
	if (!unit->term) {
		goto fail;
	}

	unit->buf = malloc(TERM_BUF_LEN);
	if (!unit->buf) {
		goto fail;
	}

	pthread_mutexattr_t attr;
	pthread_mutexattr_init(&attr);
	pthread_mutex_init(&unit->buf_mutex, &attr);

	int res = pthread_create(&unit->worker, NULL, cchar_term_worker, (void *)unit);
	if (res != 0) {
		goto fail;
	}

	return (struct cchar_unit_proto_t *) unit;

fail:
	cchar_term_shutdown((struct cchar_unit_proto_t*) unit);
	return NULL;
}

// -----------------------------------------------------------------------
void cchar_term_shutdown(struct cchar_unit_proto_t *unit)
{
	if (unit) {
		free(UNIT->buf);
		term_close(UNIT->term);
		free(UNIT);
	}
}

// -----------------------------------------------------------------------
void cchar_term_reset(struct cchar_unit_proto_t *unit)
{
}

// -----------------------------------------------------------------------
void * cchar_term_worker(void *ptr)
{
	struct cchar_unit_proto_t *unit = ptr;

	char data;

	while (1) {
		int res = term_read(UNIT->term, &data, 1);

		if (res <= 0) {
			continue;
		}

		pthread_mutex_lock(&UNIT->buf_mutex);

		UNIT->buf[UNIT->buf_wpos] = data;
		UNIT->buf_len++;
		if (UNIT->buf_wpos >= TERM_BUF_LEN-2) {
			UNIT->buf_wpos = 0;
		} else {
			UNIT->buf_wpos++;
		}

		if (UNIT->empty_read) {
			cchar_int(unit->chan, unit->num, CCHAR_TERM_INT_READY);
			UNIT->empty_read = 0;
		}

		pthread_mutex_unlock(&UNIT->buf_mutex);
	}

	pthread_exit(NULL);
}

// -----------------------------------------------------------------------
int cchar_term_read(struct cchar_unit_proto_t *unit, uint16_t *r_arg)
{
	if (UNIT->buf_len <= 0) {
		LOG(L_TERM, 50, "Term empty read");
		pthread_mutex_lock(&UNIT->buf_mutex);
		UNIT->empty_read = 1;
		pthread_mutex_unlock(&UNIT->buf_mutex);
		return IO_EN;
	} else {
		pthread_mutex_lock(&UNIT->buf_mutex);
		char data = UNIT->buf[UNIT->buf_rpos];
		LOG(L_TERM, 50, "Term read: %i (%c)", *r_arg, *r_arg);
		UNIT->buf_len--;
		if (UNIT->buf_rpos >= TERM_BUF_LEN-2) {
			UNIT->buf_rpos = 0;
		} else {
			UNIT->buf_rpos++;
		}
		UNIT->empty_read = 0;
		pthread_mutex_unlock(&UNIT->buf_mutex);
		if (data == 10) {
			return IO_NO;
		} else {
			*r_arg = data;
			return IO_OK;
		}
	}
}

// -----------------------------------------------------------------------
int cchar_term_write(struct cchar_unit_proto_t *unit, uint16_t *r_arg)
{
	char data = *r_arg & 255;
	LOG(L_TERM, 50, "Term write: %i (%c)", data, data);
	term_write(UNIT->term, &data, 1);
	return IO_OK;
}

// -----------------------------------------------------------------------
int cchar_term_cmd(struct cchar_unit_proto_t *unit, int dir, int cmd, uint16_t *r_arg)
{
	if (dir == IO_IN) {
		switch (cmd) {
		case CCHAR_TERM_CMD_SPU:
			LOG(L_TERM, 1, "TERM: SPU");
			break;
		case CCHAR_TERM_CMD_READ:
			return cchar_term_read(unit, r_arg);
		default:
			LOG(L_TERM, 1, "TERM: unknown IN command");
			break;
		}
	} else {
		switch (cmd) {
		case CCHAR_TERM_CMD_RESET:
			LOG(L_TERM, 1, "TERM: reset");
			break;
		case CCHAR_TERM_CMD_DISCONNECT:
			LOG(L_TERM, 1, "TERM: disconnect");
			break;
		case CCHAR_TERM_CMD_WRITE:
			return cchar_term_write(unit, r_arg);
		default:
			LOG(L_TERM, 1, "TERM: unknown OUT command");
			break;
		}
	}
	return IO_OK;
}

// vim: tabstop=4 shiftwidth=4 autoindent
