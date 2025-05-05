#include "vmon/config.h"
#include "vmon/ASCII.h"


#ifdef WITH_CMD_M

.global cmd_M

.text


cmd_M:
	jal		skip_whitespace
	jal		get_hex_addr			# read start addr from text buffer
	bnez	a2, cmd_M_from_last		# none given? continue from last saved addr
	mv		a3, a1					# save start addr of dump
	jal		skip_whitespace
	jal		get_hex_addr			# read end addr from text buffer
	mv		a5, a1					# save end addr of dump
	beqz	a2, cmd_M_next_line
	j		cmd_M_add_default 
cmd_M_from_last:
	# continue from last address used
	la		a1, last_address
	# TODO: this is messy
	LOAD_X	a3, 0(a1)
cmd_M_add_default:
	# no end addr? use default
	addi	a5, a3, DEFAULT_M_LINES*8-1	 
	# start addr now in a3, end addr now in a5
cmd_M_next_line:
	mv		a0, a3
	jal		print_hex
	li		a0, ':'
	jal		print_char
	# output hex bytes 
	addi	a4, a3, 8				# set end addr for output line
cmd_M_next_byte:
	beq		a3, a4, cmd_M_print_ascii  
	li		a0, ' '
	jal		print_char
	lbu		a0, 0(a3)				# get byte from memory address
	jal		print_hex_byte
	addi	a3, a3, 1
	j		cmd_M_next_byte
	# output the same hex bytes again, this time as ASCII chars
cmd_M_print_ascii:
	addi	a3, a3, -8
	li		a0, ' '
	jal		print_char
cmd_M_next_char:
	beq		a3, a4, cmd_M_ascii_done
	lbu		a0, 0(a3)			   # get byte from memory address
	jal		print_ascii
	addi	a3, a3, 1
	j		cmd_M_next_char
cmd_M_ascii_done:
	bgt		a3, a5, cmd_M_done
	jal		print_newline
	j		cmd_M_next_line
cmd_M_done:
	la		a0, last_address 
	SAVE_X	a3, 0(a0)
	j		main_prompt
.size cmd_M, .-cmd_M

#endif /* WITH_CMD_M */
