/******************************************************************************
 * Copyright (c) 2004, 2008 IBM Corporation
 * All rights reserved.
 * This program and the accompanying materials
 * are made available under the terms of the BSD License
 * which accompanies this distribution, and is available at
 * http://www.opensource.org/licenses/bsd-license.php
 *
 * Contributors:
 *     IBM Corporation - initial implementation
 *****************************************************************************/

#define STACKSIZE 0x100000
#include <macros.h>

/*
Function:	
	Input:
		r3:   
		r4:   
		r5:   prom entry	 
	Output:		

Decription: Main entry point, called from OF
	
*/
	.globl	_entry
        .section        ".opd","aw"
        .align 3
_entry:
        .quad   ._entry,.TOC.@tocbase,0
        .previous
        .size   main,24
	.globl ._entry
._entry:	
	mr	r3, r6	# parm 0 passed in r6
	mr	r4, r7	# parm 1 passed in r7	
	mr	r6, r1	# save stack pointer	
	mflr	r7	# save link register
	bcl	20,31,over	# branch after pointer table
base:	
	.align  3
.LCgot:		.quad   _got-base+0x8000
.LCstack:	.quad   _stack+STACKSIZE-0x80-base
over:	
	mflr	r8		# gpr 8 is the base
	ld	r1,.LCstack-base(r8)	# load new stack pointer
	add	r1, r1, r8		# add base
	std	r2, 64(r1)		# save got
	std	r7, 56(r1)		# save link register
#	ld	r2, .LCgot-base(r8)	# load got pointer
#	add	r2, r2, r8		# add base	
	std	r6, 0(r1)		# save stack pointer

	ld	r6, _prom_entry@got(r2)
	std	r5, 0(r6)		# Save prom handle

	ld	r10, _exit_sp@got(r2)	# save stack pointer for exit call
	std	r1, 0(r10)

	bl	._start_kernel		# call kernel init code

the_end:
	ld	r4, 56(r1)		# Restore link register
	mtlr	r4
	ld	r2, 64(r1)		# restore got
	ld	r1, 0(r1)

	blr

/*
 * Function: _callback_entry
 * Input:   r6  start address of parameter string
 *          r7  length of parameter string.
 *
 * Description: If a client application wants to register a callback function,
 *  this function is registered w/ SLOF, not the application's function. SLOF
 *  passes the parameter string in Forth representation in R6 and R7. This
 *  function moves R6 to R3 and R7 to R4 and then calls callback_entry().
 *
 */
	.globl		_callback_entry
	.section	".opd", "aw"
	.align		3
_callback_entry:
	.quad		._callback_entry,.TOC.@tocbase,0
	.previous
	.size		callback,24
	.type		._callback_entry, @function
	.globl		._callback_entry
._callback_entry:
	# Save the LR
	mflr	r0
	std	r0, 16(r1)

	# Reserve stack space
	stdu	r1,	-32(r1)

	# SLOF passes the parameters in Registers R6 and R7 but the target
	# wants them in registers R3 and R4
	mr	r3, r6
	mr	r4, r7

	# Branch to the callback_entry function
	bl	.callback_entry

	# Destroy stack frame
	ld	r1,	0(r1)

	# Restore LR
	ld	r0, 16(r1)
	mtlr	r0

	# Return to caller
	blr


	.globl  _exit_sp
_exit_sp:	.quad 0
	.globl	_prom_entry	
_prom_entry:	.quad 0

ENTRY(_exit)
	ld	r1, _exit_sp@got(r2)
	ld	r1, 0(r1)
	b	the_end

	.globl	.undo_exception
.undo_exception:
	.globl	undo_exception
undo_exception:

/* 
	unwind stack
*/
	ld      r3,exception_stack_frame@got(r2)
	ld      r1,0(r3)

	ld 	r14,0x130(r1)
	mtctr	r14

//	restore regs same as in _exception_handler:

	.irp i, 2,3,4,5,6,7,8,9,10,12,13,14,15,16, \
	        17, 18, 19, 20, 21, 22, 23, 24, 25, 26, \
		27, 28, 29, 30, 31
	ld	r\i, 0x30+\i*8 (r1)
	.endr
    addi	r1, r1, 0x130

//	restore regs as in default handler 

	ld	r0, 0x48(r1)	
	mtsrr0	r0
	ld	r0, 0x50(r1)	
	mtsrr1	r0
// 20
	ld	r0, 0x38(r1)
	mtlr	r0	
	ld	r0, 0x30(r1)
	ld	r11, 0x40(r1)
// 30
	addi 	r1, r1, 0x58

	rfid

	.lcomm	_stack,STACKSIZE,16
