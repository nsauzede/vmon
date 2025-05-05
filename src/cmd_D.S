#include "vmon/config.h"
#include "vmon/ASCII.h"


#ifdef WITH_CMD_D

.global cmd_D

.text


cmd_D:
	jal		skip_whitespace
	jal		get_hex_addr				# read start addr from text buffer
	bnez	a2, cmd_D_from_last			# none given? continue from last saved addr
	mv		a3, a1						# save start addr of dump
	jal		skip_whitespace
	jal		get_hex_addr				# read start addr from text buffer
	mv		a5, a1						# save end addr of dump
	beqz	a2, cmd_D_next_instruction
	j		cmd_D_add_default 
cmd_D_from_last:
	# continue from last address used
	la		a1, last_address
	LOAD_X	a3, 0(a1)
cmd_D_add_default:
	# no end addr? use default 
	addi	a5, a3, DEFAULT_D_LINES*4-1			 
	# start addr now in a3, end addr now in a5
cmd_D_next_instruction:
	# print memory address
	mv		a0, a3						# print current address
	jal		print_hex
	la		a0, string_asm_sep1
	jal		print_string
	# print word at this memory address
	lw		a0, 0(a3)					# load instruction word
	mv		a4, a0						# save for later
	jal		insn_is_compressed
	bnez	a0, cmd_D_word_is_RVC
cmd_D_word_not_RVC:
	lbu		a0, 3(a3)					# print 4 bytes if not compressed
	jal		print_hex_byte
	lbu		a0, 2(a3)
	jal		print_hex_byte
	lbu		a0, 1(a3)
	jal		print_hex_byte
	lbu		a0, 0(a3)
	jal		print_hex_byte
	j		cmd_D_disass	
cmd_D_word_is_RVC:					 
	lbu		a0, 1(a3)					# print 2 bytes only
	jal		print_hex_byte
	lbu		a0, 0(a3)
	jal		print_hex_byte
	li		a0, ' '
	jal		print_char					# print 4 spaces for alignment
	jal		print_char
	jal		print_char
	jal		print_char
cmd_D_disass:
	la		a0, string_asm_sep2		
	jal		print_string
	# disassemble this word
	mv		a0, a4						# get instruction word again
	jal		decode_opcode
	beqz	a1, cmd_D_opcode_unknown
	#ifdef ENABLE_RVC
	jal		adjust_RVC_add_jal_ebreak
	#endif	  
	jal		print_instruction
	j		cmd_D_advance
cmd_D_opcode_unknown:
	la		a0, string_OP_UNKNOWN
	jal		print_string
	j		cmd_D_advance
cmd_D_advance:
	mv		a0, a4						# get instruction word again
	addi	a3, a3, 2					# advance 2 bytes in any case
	jal		insn_is_compressed
	bnez	a0, cmd_D_advance_done
	addi	a3, a3, 2					# add 2 more bytes if not compressed
cmd_D_advance_done:
	bgt		a3, a5, cmd_D_done			# check if end address reached
	jal		print_newline
	j		cmd_D_next_instruction
cmd_D_done:
	la		a0, last_address 
	SAVE_X	a3, 0(a0)
	j		main_prompt
.size cmd_D, .-cmd_D


.data

string_OP_UNKNOWN:		.string "???";
.size string_OP_UNKNOWN, .-string_OP_UNKNOWN


#endif /* WITH_CMD_D */
