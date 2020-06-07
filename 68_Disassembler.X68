*-----------------------------------------------------------
* Title       : 68k Disassembler    
* Written by  : Yang Hu, Matt Johnson, Jun Park
* Date        : 06/06/2020    
* Version     : v1.0
* Description : Final project for CSS 422. Disassembles sets of machine code (see documentation) into human readable code.
*-----------------------------------------------------------

*Disassembler takes memory $1000-$xxxx
            ORG                 $1000

START:
            LEA                 WELCOME, A1       *Welcome message
            MOVE.B              #13, D0
            TRAP                #15
            MOVE.B              #0, program_counter

*-----------------------------------------------------------------------------------------------------------------------
* ADDRESS INPUT
*-----------------------------------------------------------------------------------------------------------------------
*Get start memory location (hex word) and check for bad input
_INPUT_START_ADDR
            JSR                 _CLEAR_DN
            JSR                 _PRINT_NEWLINE
            LEA                 START_ADDR, A1 *Ask for start address (hex word)
            MOVE.B              #14, D0   
            Trap                #15     
            LEA                 user_input, A1 *Get user input 
            MOVE.B              #2, D0  
            TRAP                #15 
            JSR                 _CONVERT_INPUT        
            * check if the address is odd then throw error just read right bit  
            BTST                #0, D3 *Is even?  
            BNE                 _INVALID_ADDR_ODD  * Not even then go to invalid
            * Store user Input start address to A5
            MOVE.L              D3, start_addr_loc
            MOVE.L              start_addr_loc, A5  

*Get end memory location (hex word) and check for bad input
_INPUT_END_ADDR  
            JSR                 _CLEAR_DN
            LEA                 END_ADDR, A1  *Ask for end address (hex word)
            MOVE.B              #14, D0       
            TRAP                #15 
            LEA                 end_addr_loc, A1 *Get user input 
            MOVE.B              #2, D0  
            Trap                #15 
            JSR                 _CONVERT_INPUT    
            * check if the address is odd then throw error just read right bit 
            BTST                #0, D3  
            BNE                 _INVALID_ADDR_ODD    
            * Store user Input start address to A6  
            MOVE.L              D3, end_addr_loc
            MOVE.L              end_addr_loc, A6  
            JSR                 _PRINT_NEWLINE

*Compare starting address and end address see if they make sense       
_CHECK_INPUT_ADDRESS
            JSR                 _CLEAR_DN 
            MOVE.L              A5, D2  * move starting adr to d2 to check   
            MOVE.L              A6, D3  * move ending adr to d3 to check    
            CMP.L               D3, D2  * end address is not bigger than starting addr and address same? Error  
            BGE                 _INVALID_START_END_ADDR

            JSR                 _CLEAR_DN  
            MOVE.L              #$00000000, A1  
            MOVE.L              #$00000000, A2    
            MOVE.L              #$00000000, A3    
            MOVE.L              #$00000000, A4
*-----------------------------------------------------------------------------------------------------------------------
* ADDRESS INPUT END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* DISASSEMBLE LOOP
*-----------------------------------------------------------------------------------------------------------------------
_LOOP_COUNTER 
            CMP.L               A5, A6  
            BEQ                 _REACH_END_ADR
            CMP.B               #25, program_counter  * check program counter 
            BNE                 _DISASSEMBLE_LOOP        
            JSR                 _CONTINUE 
_DISASSEMBLE_LOOP
            CMP.B               #25, program_counter  
            BEQ                 _FINISH  
            ADD.B               #1, program_counter
            MOVE.B              #0, move_counter
        *   Clear Loop  
            JSR                 _CLEAR_DN   
            MOVE.L              #$00000000, A1  
            MOVE.L              #$00000000, A2    
            MOVE.L              #$00000000, A3    
            MOVE.L              #$00000000, A4  
        *   Clear Loop  
            JSR                 _PRINT_CUR_ADDR
            LEA                 program_end, A2  * A2    store   program end 
            JSR                 ERASE_A2_MEM
            LEA                 program_end, A2  * A2    store   program end
            JSR                 _DISASSEMBLE 
            MOVE.B              #$00, (A2)+   
            LEA                 program_end, A1  
            MOVEQ               #13, D0  
            TRAP                #15 
            MOVE.B              #0, move_counter   
            BRA                 _LOOP_COUNTER
ERASE_A2_MEM
            MOVE.L              A2, D2
            ADD.L               #50, D2
ERASE_A2_LOOP
            CMP.L               D2, A2
            BEQ                 _GO_BACK
            MOVE.B              #$FF, (A2)+
            BRA                 ERASE_A2_LOOP

*Disassemble current word
_DISASSEMBLE                     * while A5 is less than A6
            MOVE.L              A5, D0
            CMP.L               A6, D0
            BGE                 _OUTPUT_RESULT
            CLR.L               D1  
            MOVE.B              (A5), D1        * read a byte from from A5, store to D1. This contains opcode
            *valid opcode bits cases: 10-EF
            CMP.W               #$10, D1             
            BLT                 _INVALID_OPCODE   * invalid, need to move on to the next word
            CMP.W               #$3F, D1          * 0001 - 0011 -> -> 10 - 3F -> MOVE, MOVEA            * 
            BLE                 _MOVE_MOVEA
            CMP.W               #$4F, D1          * 0100 -> 40 - 4F -> MOVEM, LEA, JSR, RTS
            BLE                 _MOVEM_LEA_JSR_RTS
            CMP.W               #$6F, D1           * 0110 -> 50 - 5F -> BCC (note it should not be 5F)
            BLE                 _BXX 
            CMP.W               #$80, D1           * 60 - 7F invalid
            BLT                 _INVALID_OPCODE    * invalid, need to move on to the next word
            CMP.W               #$8F, D1           * 1000 -> 80 - 8F -> OR
            BLE                 _OR
            CMP.W               #$9F, D1           * 1001 -> 90 - 9F -> SUB
            BLE                 _SUB
            CMP.W               #$B0, D1           * A0 - AF invalid
            BLT                  _INVALID_OPCODE    * invalid, need to move on to the next word
            CMP.W               #$BF, D1           * 1011 -> B0 - BF -> CMP
            BLE                 _CMP
            CMP.W               #$CF, D1           * 1100 -> C0- CF -> AND
            BLE                 _AND
            CMP.W               #$DF, D1           * 1101 -> D0 - DF -> ADD
            BLE                 _ADD
            CMP.W               #$EF, D1           * 1110 -> E0 - EF -> LSL, ASR
            BLE                 _LSL_ASR        
_INVALID_OPCODE                   * skip to the next word
            LEA                 program_end, A2  * A2    store   program end
            JSR                 ERASE_A2_MEM
            LEA                 program_end, A2  * A2    store   program end
            MOVE.B              #'D', (A2)+
            MOVE.B              #'A', (A2)+
            MOVE.B              #'T', (A2)+
            MOVE.B              #'A', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #0, D4      *   set up counter 0 at d4  
            MOVE.B              #'$', (A2)+       * push it in this program ending memory 
            MOVE.W              (A5)+, D3  * increase word size address and store it in D3 
            CLR.L               D1          * clear d1 to use as a counter  
            MOVE.B              #4, D1      * set up counter at d1  
            JSR                 _GET_WORD_VALUE   
            RTS
*-----------------------------------------------------------------------------------------------------------------------
* DISASSEMBLE LOOP END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* MOVE FAMILY (included branch to JSR LEA RTS)
*-----------------------------------------------------------------------------------------------------------------------
*Precondition: A5 points to the first byte of the current machine code, D1 contains the first byte of the command      
_MOVE_MOVEA
            MOVE.B              #'M', (A2)+   
            MOVE.B              #'O', (A2)+   
            MOVE.B              #'V', (A2)+  
            MOVE.B              #'E', (A2)+ 
            JSR                 _PREPARE_DATA_REG
            CLR.L               D0
            MOVE.L              D1, D0
            LSR.W               #8, D0
            LSR.W               #4, D0
            CMP.B               #1, D2
            BNE                 _MOVE_MOVEA_SIZE
            MOVE.B              #'A', (A2)+
            
_MOVE_MOVEA_SIZE
            LEA                 _MOVE_MOVEA_SRC, A0   
            MOVE.W              D1, D6    
            ANDI.W              #$3000, D6    
            CMP.W               #$3000, D6  
            BEQ                 _PRINT_WORD
            CMP.W               #$2000, D6  
            BEQ                 _PRINT_LONGWORD
            CMP.B               #1, D2
            BEQ                 _INVALID_OPCODE
            JMP                 _PRINT_BYTE

_MOVE_MOVEA_SRC
            MOVE.L              D3, D6
            CMP.W               #$4, D4
            BLE                 _TO_EA
_IS_SEVEN
            CMP.W               #$7, D4
            BNE                 _INVALID_OPCODE
_TO_EA
            JSR                 _EA
            MOVE.B              #',', (A2)+  

_MOVE_MOVEA_DEST
            MOVE.L              D2, D4      
            MOVE.L              D6, D5
            CMP.B               #$000, D4
            BEQ                 _TO_EA_2   
            CMP.B               #$1, D4
            BEQ                 _TO_EA_2 
            CMP.B               #$2, D4
            BEQ                 _TO_EA_2 
            CMP.B               #$3, D4
            BEQ                 _TO_EA_2 
            CMP.W               #$4, D4
            BEQ                 _TO_EA_2 
            CMP.W               #$7,D4
            BEQ                 _TO_EA_2 
            BRA                 _INVALID_OPCODE
_TO_EA_2
            JSR                 _EA
            RTS  

*______________________MOVEM_LEA_JSR_RTS____________________    
_MOVEM_LEA_JSR_RTS
            * clear before use  
            CLR.L               D0  
            CLR.L               D2      
            CLR.L               D3  
            CLR.L               D5  
            CLR.L               D6  
            CLR.L               D7  
            MOVE.W              (A5)+, D2  * load full opcode  
            MOVE.W              D2, D3
            CMP.B               #$48, D1 
            BEQ                 _MOVEM  
            CMP.W               #$4C, D1  
            BEQ                 _MOVEM  
            * check second hex to determine if it is movem or others
            * movem is 1100 or 1000 others are 1110, 1110, and 1111~ xxx1   
            ANDI.W              #$0100, D3    
            CMP.W               #$0100, D3  *   
            BEQ                 _LEA_JSR_RTS 
            BRA                 _LEA_JSR_RTS

*_______________MOVEM instruction____________________________________        
_MOVEM  
            * so i need to catch the case before it store movem 
            MOVE.B              #'M', (A2)+   
            MOVE.B              #'O', (A2)+   
            MOVE.B              #'V', (A2)+   
            MOVE.B              #'E', (A2)+   
            MOVE.B              #'M', (A2)+   
            MOVE.B              #'.', (A2)+   
            JSR                 _MOVEM_SIZE  
            CLR.L               D4 
            MOVE.W              D2, D4  
            * check dr to decide wheather m->r or r -> m    
            * basic logic
            * xxxx xXxx, it is the second bit of the 2nd hex bit either 1 or 0  
            ANDI.W              #$0400, D4  
            CMP.W               #$0400, D4  
            BEQ                 _MEM_TO_REGISTER    
            CMP.W               #$0000, D4  
            BEQ                 _REGISTER_TO_MEM    
            BRA                 _INVALID_OPCODE

_MEM_TO_REGISTER
            * register to memory 010, 100, 111, 111 works else error
            CLR.L               D0  
            CLR.L               D1      
            CLR.L               D3  
            CLR.L               D5  
            CLR.L               D6  
            CLR.L               D7  
            CLR.L               D6
            MOVE.W              (A5)+, D6
            MOVE.L              D2, D1
            MOVE.L              D2, D0
            CLR.L               D2
            JSR                 _PREPARE_DATA
            JSR                 _EA
            MOVE.B              #',', (A2)+
            MOVE.L              D0, D1
            JSR                 _PREPARE_DATA
            MOVE.W              #$FFFF, D7
            CMP.W               #2, D4
            BEQ                 _REG_TO_MEM_LIST
            CMP.W               #3, D4
            BEQ                 _REG_TO_MEM_LIST
            CMP.W               #7, D4
            BEQ                 _REG_TO_MEM_LIST
            BRA                 _INVALID_OPCODE

_REGISTER_TO_MEM
            * register to memory 010, 100, 111, 111 works else error
            CLR.L               D0  
            CLR.L               D1      
            CLR.L               D3  
            CLR.L               D5  
            CLR.L               D6  
            CLR.L               D7  
            CLR.L               D6
            MOVE.W              (A5)+, D6
            MOVE.L              D2, D0
            MOVE.L              D2, D1
            CLR.L               D2
            JSR                 _PREPARE_DATA
            CMP.W               #2, D4
            BEQ                 _REG_TO_MEM_LIST
            CMP.W               #4, D4
            BEQ                 _REG_TO_MEM_LIST_PRE
            CMP.W               #7, D4
            BEQ                 _REG_TO_MEM_LIST
            BRA                 _INVALID_OPCODE

_REG_TO_MEM_LIST
            CMP.W               #0, D6       
            BEQ                 _INVALID_OPCODE
            MOVE.B              D6, D5
            LSR.W               #8, D6
            MOVE.L              #0, D1
            MOVE.L              #$FFFF, D2
            MOVE.L              #$FFFF, D3

_REG_TO_MEM_ALOOP
            LEA                 _REG_TO_MEM_ALOOP, A0
            CMP.B               #8, D1
            BEQ                 _REG_TO_MEM_ALOOP_PRINT
            LSR.B               #1, D6
            BCS                 _CHECK_D2D3
            ADD.B               #1, D1
            BRA                 _REG_TO_MEM_ALOOP
_CHECK_D2D3
            CMP.W               #$FFFF, D2
            BEQ                 _SET_D2
_SET_D3
            MOVE.W              D1, D3
            ADD.B               #1, D1
            JMP                 (A0)
_SET_D2    
            MOVE.W              D1, D2
            ADD.B               #1, D1
            JMP                 (A0) 

_REG_TO_MEM_ALOOP_PRINT
            CMP.W               #$FFFF, D2
            BEQ                 _PREPARE_REG_TO_MEM_DLOOP
            MOVE.B              #'A', (A2)+
            ADD.W               #$30, D2   
            MOVE.B              D2, (A2)+
            CMP.W               #$FFFF, D3
            BEQ                 _PREPARE_REG_TO_MEM_DLOOP1
            MOVE.B              #'-', (A2)+
            MOVE.B              #'A', (A2)+
            ADD.W               #$30, D3   
            MOVE.B              D3, (A2)+
            BRA                 _PREPARE_REG_TO_MEM_DLOOP1
_PREPARE_REG_TO_MEM_DLOOP1
            MOVE.B              #'/', (A2)+        
_PREPARE_REG_TO_MEM_DLOOP
            MOVE.L              #0, D1
            MOVE.L              #$FFFF, D2
            MOVE.L              #$FFFF, D3
_REG_TO_MEM_DLOOP
            LEA                 _REG_TO_MEM_DLOOP, A0
            CMP.B               #8, D1
            BEQ                 _REG_TO_MEM_DLOOP_PRINT
            LSR.B               #1, D5
            BCS                 _CHECK_D2D3
            ADD.B               #1, D1
            BRA                 _REG_TO_MEM_DLOOP
_REG_TO_MEM_DLOOP_PRINT
            CMP.W               #$FFFF, D2
            BNE                 _HAS_D
            SUB.L               #1, A2
            BRA                 _PRE_REG_TO_MEM_EA
_HAS_D
            MOVE.B              #'D', (A2)+
            ADD.W               #$30, D2   
            MOVE.B              D2, (A2)+
            CMP.W               #$FFFF, D3
            BEQ                 _PRE_REG_TO_MEM_EA
            MOVE.B              #'-', (A2)+
            MOVE.B              #'D', (A2)+
            ADD.W               #$30, D3   
            MOVE.B              D3, (A2)+
_PRE_REG_TO_MEM_EA
            CMP.W               #$FFFF, D7
            BEQ                 _GO_BACK

_REG_TO_MEM_EA
            MOVE.L              D0, D1
            MOVE.B              #',', (A2)+
            JSR                 _PREPARE_DATA
            JSR                 _EA
            RTS    

_REG_TO_MEM_LIST_PRE
            *Use d6 for list
            CMP.W               #0, D6
            BEQ                 _INVALID_OPCODE
            MOVE.L              #0, D1
            MOVE.L              #$FFFF, D2
            MOVE.L              #$FFFF, D3
_REG_TO_MEM_ALOOP_PRE
            LEA                 _REG_TO_MEM_ALOOP_PRE, A0
            CMP.B               #8, D1
            BEQ                 _REG_TO_MEM_ALOOP_PRINT_PRE
            LSL.B               #1, D6
            BCS                 _CHECK_D2D3_PRE
            ADD.B               #1, D1
            BRA                 _REG_TO_MEM_ALOOP_PRE
_CHECK_D2D3_PRE
            CMP.W               #$FFFF, D2
            BEQ                 _SET_D2_PRE
_SET_D3_PRE
            MOVE.W              D1, D3
            ADD.B               #1, D1
            JMP                 (A0)
_SET_D2_PRE    
            MOVE.W              D1, D2
            ADD.B               #1, D1
            JMP                 (A0) 

_REG_TO_MEM_ALOOP_PRINT_PRE
            CMP.W               #$FFFF, D2
            BEQ                 _PREPARE_REG_TO_MEM_DLOOP_PRE
            MOVE.B              #'A', (A2)+
            ADD.W               #$30, D2   
            MOVE.B              D2, (A2)+
            CMP.W               #$FFFF, D3
            BEQ                 _PREPARE_REG_TO_MEM_DLOOP1_PRE
            MOVE.B              #'-', (A2)+
            MOVE.B              #'A', (A2)+
            ADD.W               #$30, D3   
            MOVE.B              D3, (A2)+
            BRA                 _PREPARE_REG_TO_MEM_DLOOP1_PRE
_PREPARE_REG_TO_MEM_DLOOP1_PRE
            MOVE.B              #'/', (A2)+        
_PREPARE_REG_TO_MEM_DLOOP_PRE
            MOVE.L              #0, D1
            MOVE.L              #$FFFF, D2
            MOVE.L              #$FFFF, D3
_REG_TO_MEM_DLOOP_PRE
            LEA                 _REG_TO_MEM_DLOOP_PRE, A0
            CMP.B               #8, D1
            BEQ                 _REG_TO_MEM_DLOOP_PRINT_PRE
            LSL.W               #1, D6
            BCS                 _CHECK_D2D3_PRE
            ADD.B               #1, D1
            BRA                 _REG_TO_MEM_DLOOP_PRE
_REG_TO_MEM_DLOOP_PRINT_PRE
            CMP.W               #$FFFF, D2
            BNE                 _HAS_D_PRE
            SUB.L               #1, A2
            BRA                 _REG_TO_MEM_EA
_HAS_D_PRE
            MOVE.B              #'D', (A2)+
            ADD.W               #$30, D2   
            MOVE.B              D2, (A2)+
            CMP.W               #$FFFF, D3
            BEQ                 _REG_TO_MEM_EA
            MOVE.B              #'-', (A2)+
            MOVE.B              #'D', (A2)+
            ADD.W               #$30, D3   
            MOVE.B              D3, (A2)+
            BRA                 _REG_TO_MEM_EA

* basic logic
* its always going to be either 11xx or 10xx    
* the second bit is the one decide the size 
* compare with 0040 and 0000 then its word 0100 then its lw 
_MOVEM_SIZE  
            MOVE.W              D2, D4  * get data stored in address
            ANDI.W              #$0040, D4   * prepare for compare
            CMP.W               #$0040,  D4    
            BEQ                 _MOVEM_L_SIZE 
            MOVE.B              #'W', (A2)+
            MOVE.B              #' ', (A2)+ 
            RTS      
_MOVEM_L_SIZE 
            MOVE.B              #'L', (A2)+  
            MOVE.B              #' ', (A2)+ 
            RTS    
*-----------------------------------------------------------------------------------------------------------------------
* MOVE FAMILY END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* LEA JSR RTS END
*-----------------------------------------------------------------------------------------------------------------------
_LEA_JSR_RTS
            MOVE.W              D2, D4  
            ANDI.W              #$00C0, D4  
            CMP.W               #$00C0, D4  
            BEQ                 _LEA 
            CMP.W               #$0080, D4  
            BEQ                 _JSR 
            CMP.W               #$0040, D4    
            BEQ                 _RTS 

_JSR 
            CLR.L               D4  
            CLR.L               D3  
            CLR.L               D5  
            MOVE.W              D2, D4  * store for basic check validation    
            ANDI.W              #$00F0, D4    * perform test with 1111 on third hex, whatever it matches with 1 result out 1    
            CMP.W               #$0090, D4    *  already 10xx, 10 part is confirm, to obtain retain two digits 01 then 010  
            BEQ                 _PRINT_JSR_010   
            CLR.L               D4  * if not same then reset D4 and store value again for validation check  
            MOVE.W              D2, D4      * store it in cleared D4    
            ANDI.W              #$00FF, D4    * perform 1111 1111   
            CMP.W               #$00B8, D4    *  already 10xx xxxx is confirm, to obtain xx xxxx check with 111 000 then it is 111 000    
            BEQ                 _PRINT_JSR_111_000   
            CLR.L               D4  * if not same then reste D4 and store value again for validation check  
            MOVE.W              D2, D4  * store it in cleared D4    
            ANDI.W              #$00FF, D4    * same logic  
            CMP.W               #$00B9, D4    * 10xx xxxx -> check x bits either 111 001 then 111 001     
            BEQ                 _PRINT_JSR_111_001   
            * rest its invalid   
_PRINT_JSR_010   
            MOVE.B              #'J', (A2)+   * push it in this program ending memory    
            MOVE.B              #'S', (A2)+   * push it in this program ending memory
            MOVE.B              #'R', (A2)+   * push it in this program ending memory
            MOVE.B              #' ', (A2)+   * push it in this program ending memory 
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            * shift 3 bits to check if it is 010    
            CLR.L               D4  * clear d4
            CLR.L               D3  * clear d3 
            MOVE.W              D2, D3  
            ROR.W               #3, D3    * shift register field to the front to make mode is the last 3 bits   
            MOVE.W              D3, D4  
            ANDI.W              #$0002, D4 * to check xxxx xxxx xx01 ?xxx, ? should be 0    
            CMP.W               #$0002, D4       * check if last two bits are 10 if not invalid not 010  
            BNE                 _INVALID_OPCODE * if not just invalid    
            CLR.L               D4  * after check clear d4  
            MOVE.W              D2, D4  
            ROR.W               #3, D4  * shift 3 bits to the end from front just to get prepare for EA_List  
            JSR                 _EA_LIST_010  
            RTS 
_PRINT_JSR_111_000   
            MOVE.B              #'J', (A2)+   * push it in this program ending memory 
            MOVE.B              #'S', (A2)+   * push it in this program ending memory 
            MOVE.B              #'R', (A2)+   * push it in this program ending memory 
            MOVE.B              #' ', (A2)+   * push it in this program ending memory 
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            CLR.L               D4              * clear d4  
            MOVE.W              D2, D4          * obtain value  
            ROR.W               #3, D4          * shift 3 bits to the end from front just to get prepare for EA_List
            JSR                 _EA_LIST_111 
            RTS 
_PRINT_JSR_111_001   
            MOVE.B              #'J', (A2)+   * push it in this program ending memory 
            MOVE.B              #'S', (A2)+   * push it in this program ending memory 
            MOVE.B              #'R', (A2)+   * push it in this program ending memory 
            MOVE.B              #' ', (A2)+   * push it in this program ending memory 
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            CLR.L               D4              * clear d4 
            MOVE.W              D2, D4          * obtain value
            ROR.W               #3, D4          * shift 3 bits to the end from front just to get prepare for EA_List
            JSR                 _EA_LIST_111 
            RTS 
*_________________RTS_______________________________
_RTS
            CLR.L               D4  
            MOVE.W              D2, D4  
            CMP.W               #$4E75, D4  * just print RTS    
            BEQ             _PRINT_RTS  
            * Below added for invalid_________________
            CMP.W               #$4E75, D4  * compare directly  
            BNE             _INVALID_OPCODE
            * not equal then simply throw error 
_PRINT_RTS
            MOVE.B              #'R', (A2)+     
            MOVE.B              #'T', (A2)+      
            MOVE.B              #'S', (A2)+   
            RTS 
*______________RTS End_____________________________        
_LEA 
            CLR.L               D3  
            CLR.L               D5  
            CLR.L               D4  
            MOVE.W              D2, D3  
            * adding for invalid things 
            ROR.W               #3, D3    
            ANDI.W              #$0007, D3
            CMP.W               #$0000, D3  * catching Dn case invalid    
            BEQ                 _INVALID_OPCODE    
            CMP.W               #$0001, D3  * caching An case invalid   
            BEQ                 _INVALID_OPCODE  
            CMP.W               #$0003, D3  * catching (An)+ case invalid   
            BEQ                 _INVALID_OPCODE    
            CMP.W               #$0004, D3  * catching -(An) case invalid   
            BEQ                 _INVALID_OPCODE  
            *____________________Invalid case done________________________
            CLR.L               D3 * edge case seems to be clear so reset address    
            MOVE.W              D2, D3  
            *  end of addling for invalid things    
            ROR.W               #3, D3  * shift 3 to obtain src mode   
            MOVE.W              D3, D5  
            MOVE.W              D3, D4  * store in D4 to use function EA_LIST and _REGISTER_LISTS    
            ANDI.W              #$0007, D3        
            CMP.W               #$0002, D3      
            BEQ                 _PRINT_LEA   
_PRINT_LEA   
            MOVE.B              #'L', (A2)+   * push it in this program ending memory
            MOVE.B              #'E', (A2)+   * push it in this program ending memory
            MOVE.B              #'A', (A2)+   * push it in this program ending memory
            MOVE.B              #' ', (A2)+   * push it in this program ending memory
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            JSR                 _EA_LISTS    
            MOVE.B              #',', (A2)+    * push it in this program ending memory
            CLR.L               D4               * clear out d4 
            MOVE.W              D2, D4           * obtain data stored in the memory 
            ROL.L               #4, D4           *  prepare to just directly go to _EA_LIST_001, for an register 
            JSR                 _EA_LIST_001 * go to A
            RTS 
*-----------------------------------------------------------------------------------------------------------------------
* LEA JSR RTS END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* B BROTHERS (Bxx)
*-----------------------------------------------------------------------------------------------------------------------   
_BXX    
        * clear out before use
            CLR.L               D0  
            CLR.L               D2      
            CLR.L               D3  
            CLR.L               D5  
            CLR.L               D6  
            CLR.L               D7  
        * clear out before use
            MOVE.W              (A5)+, D2  * load full opcode BCC, BGT, BLE same so D2 has 006x      
            MOVE.W              D2, D6        * transfer clean data to d6   
            ROL.W               #4, D6          * shift 4 (condition in front)  
            MOVE.W              D6, D5    
            ROL.W               #4, D6        * clear out 00s just to check condition   
            MOVE.W              D6, D5        * store it for safety 
            ANDI.W              #$000F, D6     * check condition    
            CMP.W               #$F, D6     * 1111 then BLE      
            BEQ                 _BLE
            CMP.W               #$E, D6     * 1110 then BGT  
            BEQ                 _BGT
            CMP.W               #$4, D6     * 0100 then BCC   
            BEQ                 _BCC
            BRA                 _INVALID_OPCODE      * else invalid  

    
_BCC
            MOVE.B              #'B', (A2)+   * Store BCC at the end of this program  
            MOVE.B              #'C', (A2)+   
            MOVE.B              #'C', (A2)+  
            BRA                 _BXX_DISPLACEMENT 

_BLE
            MOVE.B              #'B', (A2)+   * Store BLE at the end of this program 
            MOVE.B              #'L', (A2)+   
            MOVE.B              #'E', (A2)+  
            BRA  _BXX_DISPLACEMENT   
    
_BGT
            MOVE.B              #'B', (A2)+   * Store BGT at the end of this program 
            MOVE.B              #'G', (A2)+   
            MOVE.B              #'T', (A2)+  
            BRA                 _BXX_DISPLACEMENT

_BXX_DISPLACEMENT    
            MOVE.B              #' ', (A2)+   * little space
            MOVE.B              #' ', (A2)+    * little space
            MOVE.B              #' ', (A2)+    * little space
            MOVE.B              #' ', (A2)+    * little space
            MOVE.B              #' ', (A2)+    * little space
            MOVE.B              #0, D0  *   set up counter 0 to 8, its for byte 
            MOVE.B              #8, D3  *   counter max  
            MOVE.W              D2, D6  *   Load full memory 
            MOVE.L              A5, D5  *   Load current starting adr from user 
            ANDI.W              #$00FF, D6  *   00XX   
            CMP.W               #$FF, D6  *   if  FF then it should be 16 bits displacement   
            BEQ                 _BXX_DISPLACEMENT_LONG      
            CMP.W               #$00, D6  *   if 00 then it should be 8bit displacement (word)    
            BEQ                 _BXX_DISPLACEMENT_WORD 
            BRA                 _BXX_DISPLACEMENT_8BIT   *   rest of them are 8 bit  


_BXX_DISPLACEMENT_8BIT
            ROL.B               #1, D6  * used 6450 -> xx50 -> 0101 0000 -> 1010 xxxx   
            BCS                 _BXX_LAST_ONES_CONVERT   *   Convert 1s  
            ADDI.B              #1, D6  
            BRA                 _BXX_TWOS_COMPLEMENT_CALC

_BXX_LAST_ONES_CONVERT   
            SUBI.B              #1, D6  
            BRA                 _BXX_TWOS_COMPLEMENT_CALC
        
_BXX_TWOS_COMPLEMENT_CALC   
            ADDI.B              #1, D0  *   Increase counter set up at displacement  
            CMP.B               D0, D3  *   Check if it is last loop        
            BEQ                 _BXX_TWOS_COMP_LAST_ADD     *   complement done go to add   
            CMP.B               #8, D3  *   Check if the size is for 8bit   
            BEQ                 _BXX_DISPLACEMENT_8BIT 
            CMP.B               #16,    D3  * Check for the 16 bits disp
            BEQ                 _BXX_COMPLEMENT_WORD
            BRA                 _BXX_TWOS_COMP_LAST_ADD 

_BXX_DISPLACEMENT_WORD
            MOVE.B              #16,    D3  * set up counter for word   16 bits 
            MOVE.W              (A5)+,  D6  * store the next memory for displacement next word       
            MOVE.W              D6, D1  *   copy next word to d1 to test    
            ANDI.W              #$8000, D1  *   Set up to test if it has to go back
            CMP.W               #$8000, D1  
            BNE                 _BXX_DISPLACEMENT_W_JUST_PRINT    * Not equal then just print
_BXX_COMPLEMENT_WORD    
            ROL.W               #1, D6  *   check word size bit 
            BCS                 _BXX_LAST_ONES_CONVERT   *   convert 1s  
            ADDI.B              #1, D6  *   these are 0s    
            BRA                 _BXX_TWOS_COMPLEMENT_CALC  

_BXX_DISPLACEMENT_W_JUST_PRINT
            ADD.W               D6, D5  * just print (add d6 to current adr)
            BRA                 _BXX_DISPLAY *   go to display   

_BXX_DISPLACEMENT_LONG   
            * will be implemented
            MOVE.B              #32,    D3  * set up counter for longword 32 bit    
            MOVE.L              (A5)+,  D6  * store next longword size memory value 
            MOVE.L              D6, D1  * copy  next longword to d1 to test 
            ANDI.L              #$80000000, D1  *   Set up to test if it has to go back  
            CMP.L               #$80000000,    D1  
            BNE                 _BXX_DISPLACEMENT_L_JUST_PRINT       * Not equal then just print
_BXX_COMPLEMENT_LONG     
            ROL.W               #1, D6  *   check word size bit 
            BCS                 _BXX_LAST_ONES_CONVERT   *   convert 1s  
            ADDI.B              #1, D6  *   these are 0s    
            BRA                 _BXX_TWOS_COMPLEMENT_CALC      

_BXX_DISPLACEMENT_L_JUST_PRINT        
            ADD.L               D6, D5  *   just print (Add d6 to current adr)  
            BRA                 _BXX_DISPLAY  
_BXX_TWOS_COMP_LAST_ADD   
            ADDI.W              #$1,    D6  *   Add 1 at the end to the bit   
            SUB.L               D6, D5  

_BXX_DISPLAY    
            CMP.L               #$FFFF, D5  *   check if the size is for longword size
            BGT                 _BXX_DISPLAY_LONG
            MOVE.B              #4, D3  
            CLR.L               D7  
            JSR                 _ASCII_CONVERT_BXX   
            RTS 
_BXX_DISPLAY_LONG
_ASCII_CONVERT_BXX
            ROL.W               #4, D5  
            MOVE.L              D5, D4  
            ANDI.L              #$0000000F, D4  *   just compare last 4 bits
            CMPI.B              #$09,   D4      *   check is number or letter      
            BLE                 _IS_NUM 
            ADDI.B              #$37,   D4      * is letter 
            BRA                 _IS_LETTER   
_IS_NUM  
            ADDI.B              #$30,   D4      * is nubmer 
            BRA                 _IS_LETTER  
_IS_LETTER  
            ADDI.B              #1, D7    
            MOVE.B              D4, (A2)+   
            CMP.B               D3, D7    
            BLT                 _ASCII_CONVERT_BXX
            RTS
*-----------------------------------------------------------------------------------------------------------------------
* B BROTHERS (Bxx) END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* ADD
*-----------------------------------------------------------------------------------------------------------------------
_ADD
            MOVE.B              #'A',   (A2)+  
            MOVE.B              #'D',   (A2)+   
            MOVE.B              #'D',   (A2)+   
            MOVE.W              (A5)+,   D2
            MOVE.W              D2, D6
            ANDI.W              #$01C0, D6   
            CMP.W               #$0000, D6
            BEQ                 _B_EA_DN     
            CMP.W               #$0040, D6  
            BEQ                 _W_EA_DN 
            CMP.W               #$0080,  D6      
            BEQ                 _L_EA_DN
            CMP.W               #$0100, D6  
            BEQ                 _B_DN_EA 
            CMP.W               #$0140, D6  
            BEQ                 _W_DN_EA 
            CMP.W               #$0180, D6  
            BEQ                 _L_DN_EA 
            BRA                 _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* ADD END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* AND
*-----------------------------------------------------------------------------------------------------------------------
_AND
            MOVE.B              #'A',   (A2)+  
            MOVE.B              #'N',   (A2)+   
            MOVE.B              #'D',   (A2)+   
            MOVE.W              (A5)+,   D2
            MOVE.W              D2, D6
            ANDI.W              #$01C0, D6
            CMP.W               #$0000, D6 
            BEQ                 _B_EA_DN  
            CMP.W               #$0100, D6  
            BEQ                 _B_DN_EA
            CMP.W               #$0040, D6  
            BEQ                 _W_EA_DN 
            CMP.W               #$0140, D6  
            BEQ                 _W_DN_EA
            CMP.W               #$0080,  D6      
            BEQ                 _L_EA_DN  
            CMP.W               #$0180, D6  
            BEQ                 _L_DN_EA
            BRA                 _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* AND END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* CMP
*-----------------------------------------------------------------------------------------------------------------------
_CMP
            MOVE.B              #'C',   (A2)+  
            MOVE.B              #'M',   (A2)+   
            MOVE.B              #'P',   (A2)+
            MOVE.W              (A5)+,   D2
            MOVE.W              D2, D6
            ANDI.W              #$01C0, D6
            CMP.W               #$0000, D6 
            BEQ                 _B_EA_DN  
            CMP.W               #$0040, D6  
            BEQ                 _W_EA_DN 
            CMP.W               #$0080,  D6      
            BEQ                 _L_EA_DN  
            BRA                 _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* CMP END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* OR
*-----------------------------------------------------------------------------------------------------------------------
_OR
            MOVE.B              #' ',   (A2)+  
            MOVE.B              #'O',   (A2)+   
            MOVE.B              #'R',   (A2)+   
            MOVE.W              (A5)+,   D2
            MOVE.W              D2, D6
            ANDI.W              #$01C0, D6
            CMP.W               #$0000, D6
            BEQ                 _B_EA_DN     
            CMP.W               #$0040, D6  
            BEQ                 _W_EA_DN 
            CMP.W               #$0080,  D6      
            BEQ                 _L_EA_DN
            CMP.W               #$0100, D6  
            BEQ                 _B_DN_EA 
            CMP.W               #$0140, D6  
            BEQ                 _W_DN_EA 
            CMP.W               #$0180, D6  
            BEQ                 _L_DN_EA 
            BRA                 _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* OR END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* SUB
*-----------------------------------------------------------------------------------------------------------------------
_SUB
            MOVE.B              #'S',   (A2)+
            MOVE.B              #'U',   (A2)+
            MOVE.B              #'B',   (A2)+
            MOVE.W              (A5)+,   D2    
            MOVE.W              D2, D6
            ANDI.W              #$01C0, D6  
            CMP.W               #$0000, D6
            BEQ                 _B_EA_DN     
            CMP.W               #$0040, D6  
            BEQ                 _W_EA_DN 
            CMP.W               #$0080,  D6      
            BEQ                 _L_EA_DN
            CMP.W               #$0100, D6  
            BEQ                 _B_DN_EA 
            CMP.W               #$0140, D6  
            BEQ                 _W_DN_EA 
            CMP.W               #$0180, D6  
            BEQ                 _L_DN_EA 
            BRA                 _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* SUB END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* GENERAL SUBROUTINES (Used by ADD, AND, CMP, OR, and SUB)
*-----------------------------------------------------------------------------------------------------------------------
*Clear all 8 data registers
_CLEAR_DN
            CLR.L               D0
            CLR.L               D1
            CLR.L               D2
            CLR.L               D3
            CLR.L               D4
            CLR.L               D5
            CLR.L               D6
            CLR.L               D7
            RTS

*Prints \n
_PRINT_NEWLINE
            LEA                 NEWLINE, A1
            MOVE.B              #14, D0
            TRAP                #15
            RTS 

*Push '.B' into output
_B
            MOVE.B              #'.', (A2)+
            MOVE.B              #'B', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            RTS

*Push '.W' into output
_W
            MOVE.B              #'.', (A2)+
            MOVE.B              #'W', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            RTS

*Push '.L' into output
_L
            MOVE.B              #'.', (A2)+
            MOVE.B              #'L', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            MOVE.B              #' ', (A2)+
            RTS

_ELSE

*General operand subroutine for '.B' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_B_DN_EA
            JSR                 _B
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            MOVE.B              #',', (A2)+ 
            JSR                 _CALC_EA_MODE
            RTS

*General operand subroutine for '.B' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_B_EA_DN
            JSR                 _B
            JSR                 _CALC_EA_MODE
            MOVE.B              #',', (A2)+ 
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            RTS

*General operand subroutine for '.W' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_W_DN_EA
            JSR                 _W
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            MOVE.B              #',', (A2)+ 
            JSR                 _CALC_EA_MODE
            RTS

*General operand subroutine for '.W' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_W_EA_DN
            JSR                 _W
            JSR                 _CALC_EA_MODE
            MOVE.B              #',', (A2)+ 
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            RTS

*General operand subroutine for '.L' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_L_DN_EA
            JSR                 _L
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            MOVE.B              #',', (A2)+ 
            JSR                 _CALC_EA_MODE
            RTS

*General operand subroutine for '.L' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_L_EA_DN
            JSR                 _L
            JSR                 _CALC_EA_MODE
            MOVE.B              #',', (A2)+ 
            MOVE.B              #'D', (A2)+
            MOVE.W              D2, D4  
            ANDI.W              #$0E00, D4
            LSR.W               #4, D4
            LSR.W               #4, D4 
            LSR.W               #1, D4  
            MOVE.W              D4, D5
            MOVE.W              D4, D3
            ANDI.W              #$0007, D4
            JSR                 _REGISTER_LISTS
            RTS
*-----------------------------------------------------------------------------------------------------------------------
* GENERAL SUBROUTINES END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* EA (Used by ADD, AND, CMP, OR, and SUB)
*-----------------------------------------------------------------------------------------------------------------------
* Basic idea
* 000 to 110 so, need to compare with three bits
* Shift until the the Mode in EA is the last bit    
* Simply check the shifted last 3 bit (mode)
*  000 and 111 -> 000
*  001 and 111 - > 001
*  010 and 111 -> 010 etc etc 
_CALC_EA_MODE   
            MOVE.W          D2, D3  * move data value to d3 for shifting purpose (original data)    
            ROL.W           #4, D3  * Shift 4   Goal is to get EA MODE  
            ROL.W           #3, D3  * Shift 3  
            ROL.W           #3, D3  * Shift 3   
            ROL.W           #3, D3  * Shift 3     
            MOVE.W          D3, D4  *  Save shifted value just for safe   
            ANDI.W          #$0007, D3  * check last 3 bits which is mode it is    
            JSR             _EA_LISTS  
            RTS 
*__________________________EA MODE Lists_________________________________________   
_EA_LISTS
            CMP.W           #$000,  D3  
            BEQ             _EA_LIST_000 
            CMP.W           #$001,  D3  
            BEQ             _EA_LIST_001 
            CMP.W           #$010,  D3  
            BEQ             _EA_LIST_010 
            CMP.W           #$011,  D3  
            BEQ             _EA_LIST_011 
            CMP.W           #$100,  D3  
            BEQ             _EA_LIST_100 
            CMP.W           #$101,  D3  
            BEQ             _EA_LIST_101 
            CMP.W           #$110,  D3  
            BEQ             _EA_LIST_110 
            CMP.W           #$111,  D3  
            BEQ             _EA_LIST_111 
            *------Direct access----  
            CMP.W           #0, D3  
            BEQ             _EA_LIST_000   
            CMP.W           #1, D3  
            BEQ             _EA_LIST_001
            CMP.W           #2, D3  
            BEQ             _EA_LIST_010 
            CMP.W           #3, D3  
            BEQ             _EA_LIST_011 
            CMP.W           #4, D3  
            BEQ             _EA_LIST_100 
            CMP.W           #5, D3  
            BEQ             _EA_LIST_101 
            CMP.W           #6, D3  
            BEQ             _EA_LIST_110 
            CMP.W           #7, D3  
            BEQ             _EA_LIST_111 
            RTS 

_EA_LIST_000 
            MOVE.B          #'D',   (A2)+   
            * will reset to whatever it was so the last 3 bit is Register   
            *  MOVE.W  D3, D4  * copy the value for safety shift   
            ROL.W           #3, D4  * D4 will contains the orignial value   
            MOVE.W          D4, D3  
            ANDI.W          #$0007, D4  *   Check last 3 bits (register)    
            JSR             _REGISTER_LISTS  
            RTS 

_EA_LIST_001
            MOVE.B          #'A',   (A2)+   * push it in this program ending memory
            ROL.W           #3, D4          * obtain original data    
            MOVE.W          D4, D3          * store it for safety 
            ANDI.W          #$0007, D4      *  use AND logic 111 to obtain register ea
            JSR             _REGISTER_LISTS  
            RTS 

_EA_LIST_010
            MOVE.B          #'(',   (A2)+   * push it in this program ending memory
            MOVE.B          #'A',   (A2)+   * push it in this program ending memory
            ROL.W           #3, D4          * obtain original data
            MOVE.W          D4, D3          * store it for safety
            ANDI.W          #$0007, D4      *  use AND logic 111 to obtain register ea
            JSR             _REGISTER_LISTS  
            MOVE.B          #')',   (A2)+   * push it in this program ending memory
            RTS 

_EA_LIST_011
            MOVE.B          #'(',   (A2)+   * push it in this program ending memory
            MOVE.B          #'A',   (A2)+   * push it in this program ending memory
            ROL.W           #3, D4          * obtain original data
            MOVE.W          D4, D3          * store it for safety
            ANDI.W          #$0007, D4      *  use AND logic 111 to obtain register ea
            JSR             _REGISTER_LISTS  
            MOVE.B          #')',   (A2)+   * push it in this program ending memory
            MOVE.B          #'+',   (A2)+   * push it in this program ending memory
            RTS 

_EA_LIST_100
            MOVE.B          #'-',   (A2)+   * push it in this program ending memory
            MOVE.B          #'(',   (A2)+   * push it in this program ending memory
            MOVE.B          #'A',   (A2)+   * push it in this program ending memory
            ROL.W           #3, D4          * obtain original data
            MOVE.W          D4, D3          * store it for safety
            ANDI.W          #$0007, D4      *  use AND logic 111 to obtain register ea
            JSR             _REGISTER_LISTS  
            MOVE.B          #')',   (A2)+   * push it in this program ending memory
            RTS 

_EA_LIST_101
_EA_LIST_110
            BRA             _INVALID_OPCODE      * just invalid    

_EA_LIST_111    
            ROL.W           #3, D4      * obtain original data     
            MOVE.W          D4, D3      * store it for safety   
            ANDI.W          #$0007, D4  *  use AND logic 111 to obtain register ea  
            JSR             _REGISTER_LISTS   
            RTS  

*______________________ Lists of Registers________________________________________________  
_REGISTER_LISTS
            CMP.W           #$0000, D4  
            BEQ             _REGISTER_000   
            CMP.W           #$0001, D4  
            BEQ             _REGISTER_001
            CMP.W           #$0010, D4  
            BEQ             _REGISTER_010    
            CMP.W           #$0011, D4  
            BEQ             _REGISTER_011    
            CMP.W           #$0100, D4  
            BEQ             _REGISTER_100    
            CMP.W           #$0101, D4  
            BEQ             _REGISTER_101    
            CMP.W           #$0110, D4  
            BEQ             _REGISTER_110    
            CMP.W           #$0111, D4  
            BEQ             _REGISTER_111    
*____________ Direct Access____________________________
            CMP.W           #1, D4
            BEQ             _REGISTER_001
            CMP.W           #2, D4  
            BEQ             _REGISTER_010
            CMP.W           #3, D4  
            BEQ             _REGISTER_011   
            CMP.W           #4, D4  
            BEQ             _REGISTER_100    
            CMP.W           #5, D4  
            BEQ             _REGISTER_101    
            CMP.W           #6, D4  
            BEQ             _REGISTER_110    
            CMP.W           #7, D4  
            BEQ             _REGISTER_111 

_REGISTER_000
            MOVE.W          D3, D4      * obtain original value to D4   
            ROL.W           #8, D4      * shift to gain register      
            ROL.W           #5, D4       * shift to gain register    
            ANDI.W          #$0007, D4  * prepare to compare with 7 (111)   
            CMP.B           #$7,    D4  
            BNE             _JUST_ZERO       * not equal just print 0    
            MOVE.B          #0, D4      *   set up counter 0 at d4  
            MOVE.B          #'$',   (A2)+       * push it in this program ending memory 
            MOVE.W          (A5)+,  D3  * increase word size address and store it in D3 
            CLR.L           D1          * clear d1 to use as a counter  
            MOVE.B          #4, D1      * set up counter at d1  
            JSR             _GET_WORD_VALUE   
            RTS 

_GET_WORD_VALUE
            * get the first letter it is stored in D3   
            ROL.W           #4, D3  
            MOVE.L          D3, D7  
            ANDI.L          #$0000000F, D7     
            CMPI.B          #$09,   D7      
            BLE             _NUM_CONVER_W_SIZE      
            ADDI.B          #$37,   D7      * (letter)  
_LETTER_CONVERT_W_SIZE    
            ADDI.B          #1, D4  * increase counter    
            MOVE.B          D7, (A2)+   * push the char into  end addres    
            CMP.B           D1,  D4  * compare count 
            BLT             _GET_WORD_VALUE   * less go back  
            RTS 
_NUM_CONVER_W_SIZE  
            ADDI.B          #$30,   D7  * add 30 ascii stuffs  (num)     
            BRA             _LETTER_CONVERT_W_SIZE    

_JUST_ZERO   
            MOVE.B          #'0',    (A2)+  * push it in this program ending memory
            RTS   
    
_REGISTER_001    
            MOVE.W          D3, D4  * get the value of memory again  form is regi opmode ea mode ea regi    
            ROL.W           #8, D4  *  shift so the form now    
            ROL.W           #5, D4  * shift to get register value   
            ANDI.W          #$0007, D4    * do AND 111 to obtain register   
            CMP.B           #$7,    D4    *  not equal to 111 then its just one 
            BNE             _JUST_ONE
            MOVE.B          #0, D4          * set counter 0 at d4   
            MOVE.B          #'$',   (A2)+   * push it in this program ending memory
            MOVE.L          (A5)+,  D3  *   increase long word size address 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #8, D1          * set counter at d1 (8 cause 8 digit longword)  
            JSR             _GET_L_VALUE   
            RTS  

*Same logic applies with word function located at above  
_GET_L_VALUE
            ROL.L           #4, D3    
            MOVE.L          D3, D7  
            ANDI.L          #$0000000F, D7  
            CMPI.B          #$09,   D7  
            BLE             _NUM_CONVERT_L_SIZE    
            ADDI.B          #$37,   D7  

_LETTER_CONVERT_L_SIZE    
            ADDI.B          #1, D4  
            MOVE.B          D7, (A2)+   
            CMP.B           D1, D4  
            BLT             _GET_L_VALUE   
            RTS 

_NUM_CONVERT_L_SIZE    
            ADDI.B          #$30,   D7  
            BRA             _LETTER_CONVERT_L_SIZE    

_JUST_ONE           
            MOVE.B          #'1',   (A2)+      * push it in this program ending memory
            RTS 

_REGISTER_010
            MOVE.B          #'2',   (A2)+      * push it in this program ending memory
            RTS

_REGISTER_011
            MOVE.B          #'3',   (A2)+      * push it in this program ending memory
            RTS 

_REGISTER_100    
            MOVE.W          D3, D4  
            ROL.W           #8, D4          * shift so the form now 
            ROL.W           #5, D4           * shift to get register value
            ANDI.W          #$0007, D4      * do AND 111 to obtain register
            CMP.B           #$7,    D4      *  not equal to 111 then its just four  
            BNE             _JUST_FOUR   
            MOVE.B          #0, D4          *  set up counter 0 at d4   
            MOVE.B          #'#',   (A2)+   * push it in this program ending memory
            MOVE.B          #'$',   (A2)+   * push it in this program ending memory
            MOVE.W          D3, D7  * to determine the size to decide long or word immediate data   
            ROL.W           #4, D7  
            ROL.W           #3, D7  
            ROL.W           #3, D7  
            ANDI.W          #$0007, D7  * get opmode    
            CMP.W           #$0002, D7   
            BEQ             _LONGWORD_100 
            CMP.W           #$0006, D7  
            BEQ             _LONGWORD_100    
            BRA             _WORD_100    
            RTS 

_LONGWORD_100    
            CLR.L           D7  
            MOVE.L          (A5)+,  D3 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #8, D1  
            JSR             _GET_L_VALUE
            RTS 

_WORD_100
            MOVE.W          (A5)+,  D3  * increase word size address and store it in D3 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #4, D1   
            JSR             _GET_WORD_VALUE   
            RTS 

_JUST_FOUR
            MOVE.B          #'4',   (A2)+   * push it in this program ending memory
            RTS 

_REGISTER_101
            MOVE.B          #'5',   (A2)+   * push it in this program ending memory
            RTS 

_REGISTER_110
            MOVE.B          #'6',   (A2)+   * push it in this program ending memory
            RTS 

_REGISTER_111
            MOVE.B          #'7',   (A2)+   * push it in this program ending memory
            RTS 
*-----------------------------------------------------------------------------------------------------------------------
* EA END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* LSX ASx
*-----------------------------------------------------------------------------------------------------------------------
_LSL_ASR
        *bit 6 and 7 determines memory or register
            JSR             _PREPARE_DATA_REG
            CMP.W           #7, D2
            BEQ             _CHECKD3
            CMP.W           #3, D2
            BEQ             _CHECKD3
            CMP.B           #$1, D4
            BEQ             _LSX
            CMP.B           #$0, D4
            BEQ             _ASX
            CMP.B           #$5, D4
            BEQ             _LSX
            CMP.B           #$4, D4
            BEQ             _ASX
            BRA             _INVALID_OPCODE
_CHECKD3
            CMP.B           #0, D3
            BEQ             _ASX
            CMP.B           #1, D3
            BEQ             _LSX
            BRA             _INVALID_OPCODE  
_LSX
            MOVE.B          #'L', (A2)+
            MOVE.B          #'S', (A2)+
            CMP.W           #4, D2
            BGE             _LEFT_SHIFT
_RIGHT_SHIFT
            MOVE.B          #'R', (A2)+
            BRA             _DETERMINE_SHIFT_TYPE    
_LEFT_SHIFT
            MOVE.B          #'L', (A2)+
_DETERMINE_SHIFT_TYPE
            CMP.B           #3, D2
            BEQ             _SHIFT_MEM
            CMP.B           #7, D2
            BEQ             _SHIFT_MEM
_SHIFT_REG
            LEA             _SHIFT_TYPE, A0
            LSL.W           #8, D1
            LSR.W           #8, D1
            LSR.W           #6, D1    
            CMP.B           #0, D1
            BEQ             _PRINT_BYTE
            CMP.B           #1, D1
            BEQ             _PRINT_WORD
            CMP.B           #2, D1
            BEQ             _PRINT_LONGWORD
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            BRA             _INVALID_OPCODE
_SHIFT_TYPE
            CMP.W           #$5, D4
            BEQ             _REG_SHIFT
            CMP.W           #$1, D4
            BEQ             _NUM_SHIFT
            BRA             _INVALID_OPCODE
_REG_SHIFT
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #'D', (A2)+
            ADD.W           #$30, D3
            MOVE.B          D3, (A2)+
            BRA             _SHIFT_DEST
_NUM_SHIFT
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #'#', (A2)+
            MOVE.B          #'$', (A2)+
            CMP.W           #0, D3
            BEQ             _EIGHT
            ADD.W           #$30, D3
            MOVE.B          D3, (A2)+    
            BRA             _SHIFT_DEST
_EIGHT 
            MOVE.B          #'8', (A2)+
            BRA             _SHIFT_DEST
_SHIFT_DEST
            MOVE.B          #',', (A2)+
            MOVE.B          #'D', (A2)+
            ADD.W           #$30, D5
            MOVE.B          D5, (A2)+
            RTS
_SHIFT_MEM
            MOVE.B          #'.', (A2)+
            MOVE.B          #'W', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            CMP.W           #$2, D4
            BLT             _INVALID_OPCODE
            JSR             _EA
            RTS
_ASX
            MOVE.B          #'A', (A2)+
            MOVE.B          #'S', (A2)+
            CMP.W           #4, D2
            BGE             _LEFT_ROTATE
_RIGHT_ROTATE
            MOVE.B          #'R', (A2)+
            BRA             _DETERMINE_ROTATE_TYPE    
_LEFT_ROTATE
            MOVE.B          #'L', (A2)+
_DETERMINE_ROTATE_TYPE
            CMP.B           #3, D2
            BEQ             _ROTATE_MEM
            CMP.B           #7, D2
            BEQ             _ROTATE_MEM
_ROTATE_REG
            LEA             _ROTATE_TYPE, A0
            LSL.W           #8, D1
            LSR.W           #8, D1
            LSR.W           #6, D1    
            CMP.B           #0, D1
            BEQ             _PRINT_BYTE
            CMP.B           #1, D1
            BEQ             _PRINT_WORD
            CMP.B           #2, D1
            BEQ             _PRINT_LONGWORD
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            BRA             _INVALID_OPCODE
_ROTATE_TYPE
            CMP.W           #$4, D4
            BEQ             _REG_ROTATE
            CMP.W           #$0, D4
            BEQ             _NUM_ROTATE
            BRA             _INVALID_OPCODE
_REG_ROTATE
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #'D', (A2)+
            ADD.W           #$30, D3
            MOVE.B          D3, (A2)+
            BRA             _ROTATE_DEST
_NUM_ROTATE
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #'#', (A2)+
            MOVE.B          #'$', (A2)+
            CMP.W           #0, D3
            BEQ             _EIGHT_R
            ADD.W           #$30, D3
            MOVE.B          D3, (A2)+    
            BRA             _ROTATE_DEST
_EIGHT_R 
            MOVE.B          #'8', (A2)+
            BRA             _ROTATE_DEST
_ROTATE_DEST
            MOVE.B          #',', (A2)+
            MOVE.B          #'D', (A2)+
            ADD.W           #$30, D5
            MOVE.B          D5, (A2)+
            RTS
_ROTATE_MEM
            MOVE.B          #'.', (A2)+
            MOVE.B          #'W', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            MOVE.B          #' ', (A2)+
            CMP.W           #$2, D4
            BLT             _INVALID_OPCODE
            JSR             _EA
            RTS
*-----------------------------------------------------------------------------------------------------------------------
* LSX ASx END
*-----------------------------------------------------------------------------------------------------------------------   

*-----------------------------------------------------------------------------------------------------------------------
* OUTPUT
*-----------------------------------------------------------------------------------------------------------------------   
_OUTPUT_RESULT
_PRINT_CUR_ADDR
            MOVE.L          A5, D2 * move staring addr to d2
            MOVE.B          #0, D5  * counter to read all hex
            MOVE.B          #8, D6  * total number of address is 8 bits just to set up to compare with counter    
_CONVERT_HEX_ASCII 
            CMP.B           D5, D6  * compare the couter
            BNE             _SMALLER *   Set counter to read 4
            JSR             _BIGGER
            TRAP            #15    * extra space   
            RTS  
    
_BIGGER
            MOVE.B          #6, D0  
            MOVE.B          #32,    D1  
            RTS 
_SMALLER
            MOVE.B          #0, D3  * set counter to 0  
            MOVE.B          #4, D4  * set counter to 4  
_READ_EACH_CHAR              *   Read Each character 
            CMP.B           D3, D4  * compare the counter 
            BEQ             _SAVE_CHAR   * 4 then save char  
            LSL.L           #1, D2   * D2 has the address and do LSL to full register to    
            BCC             _APPEND_ZERO * while change to 0, does carry clear   
            ADDI.B          #1, D1  
            BRA             _NEXT_BIT  

_APPEND_ZERO 
            ADDI.B          #0, D1  * append zero because it is 0   
_NEXT_BIT
            ADDI.B          #1, D3  * increase the counter because we read  
            LSL.L           #1, D1  *  In full register value D1 make a shift 1 (0) 
            BRA             _READ_EACH_CHAR  
_SAVE_CHAR
            LSR.L           #1, D1  * in the full register value it has single digit of the address 
            CMP.B           #$A,    D1  
            BLT             _CONVERT_ASCII_HEX_DISPLAY_ADDR 
            ADDI.B          #$37,   D1  * it is letter  
            ADDI.B          #1, D5      * increase counter (it is the counter for full memory address counter which should be 8 eventually) 
            MOVE.B          #6, D0      * trap task display single char    
            TRAP            #15 
            CLR.L           D1          * clear d1  
            BRA             _CONVERT_HEX_ASCII 

_CONVERT_ASCII_HEX_DISPLAY_ADDR 
            ADDI.B          #$30,   D1  * it is number  so add 30   
            ADDI.B          #1, D5      * increase counter (it is the counter for full memory address counter which should be 8)    
            MOVE.B          #6, D0      *  trap task display single char    
            TRAP            #15 
            CLR.L           D1  * clear d1  
            BRA             _CONVERT_HEX_ASCII  

_CONVERT_INPUT        
            MOVE.B          (A1)+,  D2   
            JSR             _CONVERT_ASCII
            ADD.L           D2, D3  * copy D2 to D3     
            CMPI.B          #$0,    (A1)    
            BEQ             _GO_BACK
            LSL.L           #4, D3  * Make room for next byte  
            BRA             _CONVERT_INPUT

_GO_BACK  
            RTS    

_CONVERT_ASCII
            CMPI.B          #$30,   D2     * Any input that are less than 30 is error    
            BLT             _INVALID
            CMPI.B          #$67,   D2    * Any input that are more or equal to 67 (g) is error 
            BGE             _INVALID  
            * 30~39 Number
            * 41~46 Cap Letter Till F
            * 61~66 Till f
            CMPI.B          #$39,   D2 * 40 is immeidate data use CMPI   
            BLE             _IS_NUM_2 * If less than 40 then execute  
            *________________________________________________
            CMPI.B          #$40,   D2  *   if it is between 3A (:) and 40 (@) throw Error   
            BLE             _INVALID
            *_______________________________________________
            CMPI.B          #$41,   D2  * if not compare with 41 (A)    
            BGE             _IS_LETTER_2    *Bigger than or Equal to 41 then execute    
_IS_NUM_2
            SUB.B           #$30,   D2        
            RTS 
_IS_LETTER_2
            * figure out either small leter or capital letter   
            CMPI.B          #$46,   D2  * Compare with small letter F            
            BLE             _IS_UPPERCASE   * if less or equal to 46 than small letter     
            BRA             _IS_LOWERCASE * else go to capital letter 
_IS_UPPERCASE   
            SUB.B           #$37,   D2   * 46 - 37 = F
            RTS 
_IS_LOWERCASE  
            CMPI.B          #$60,   D2  * if less than or equal to 60 (') throw Error   
            BLE             _INVALID
            SUB.B           #$57,   D2    
            RTS
*-----------------------------------------------------------------------------------------------------------------------
* OUTPUT END
*-----------------------------------------------------------------------------------------------------------------------   

*-----------------------------------------------------------------------------------------------------------------------
* EA2 (Used by )
*-----------------------------------------------------------------------------------------------------------------------   
_PREPARE_DATA_REG
            LSL             #8, D1 
            ADDA            #1, A5
            MOVE.B          (A5)+, D1            * full opcode word in D1
_PREPARE_DATA    
            MOVE.W          D1, D2              * copy D1 to D2, for dest mode
            MOVE.W          D1, D3              * copy D1 to D3, for dest register
            MOVE.W          D1, D4              * copy D1 to D2, for src mode
            MOVE.W          D1, D5              * copy D1 to D5, for src register
        
            LSL.W           #7,  D2   
            LSR.W           #8,  D2                     
            LSR.W           #5,  D2             * now D2 in binary: 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest mode

            LSL.W           #4,  D3              
            LSR.W           #8,  D3                     
            LSR.W           #5,  D3             * now D3 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest register
            
            LSL.W           #8,  D4 
            LSL.W           #2,  D4             
            LSR.W           #8,  D4                     
            LSR.W           #5,  D4             * now D4 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src mode
            
            LSL.W           #8,  D5  
            LSL.W           #5,  D5
            LSR.W           #8,  D5               
            LSR.W           #5,  D5             * now D5 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src register
            RTS

_EA
            CMP.B           #0, D4
            BEQ             _PRINT_DATA_REG_1 
            CMP.B           #1, D4 
            BEQ             _PRINT_ADDRESS_REG_1
            CMP.B           #2, D4
            BEQ             _PRINT_PAREN_ADDRESS_REG_1
            CMP.B           #3, D4
            BEQ             _PRINT_INCRE_ADDRESS_REG_1
            CMP.W           #$4, D4
            BEQ             _PRINT_DECRE_ADDRESS_REG_1
            CMP.W           #$7,D4
            BEQ             _PRINT_ABSOLUTE_IMMEDIATE_DATA_1

_PRINT_ABSOLUTE_IMMEDIATE_DATA_1                    
            CMP.B           #4, D5
            BEQ             _PRINT_IMMEDIATE_DATA_1
            CMP.B           #0, D5
            BEQ             _PRINT_ABSOLUTE_ADDRESS_1
            CMP.B           #1, D5
            BEQ             _PRINT_ABSOLUTE_ADDRESS_1
            BRA             _INVALID_OPCODE

_PRINT_IMMEDIATE_DATA_1
            *if size is byte or word
            CMP.B           #2, D0
            BEQ             _READ_LONG_WORD_1
            *if size is byte or word
            CLR.L           D3
            CLR.L           D4
            MOVE.B          #0, D4  
            MOVE.B          #'#',   (A2)+   
            MOVE.B          #'$',   (A2)+   
            MOVE.W          (A5)+,  D3  * increase word size address and store it in D3 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #4, D1     
            JSR             _GET_WORD_VALUE 
            RTS

_READ_LONG_WORD_1    
            MOVE.B          #0, D4  
            MOVE.B          #'#',   (A2)+   
            MOVE.B          #'$',   (A2)+   
            MOVE.L          (A5)+,  D3  *   increase long word size address 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #8, D1  
            JSR             _GET_L_VALUE   
            RTS

_PRINT_ABSOLUTE_ADDRESS_1
            CMP.B           #0, D5
            BEQ             _WORD_ADDR_1
            CMP.B           #1, D5
            BEQ             _LONGWORD_ADDR_1
            BRA             _INVALID_OPCODE
_LONGWORD_ADDR_1
            MOVE.B          #0, D4  
            MOVE.B          #'$',   (A2)+   
            MOVE.L          (A5)+,  D3  *   increase long word size address 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #8, D1  
            JSR             _GET_L_VALUE   
            RTS
_WORD_ADDR_1
            CLR.L           D3
            CLR.L           D4
            MOVE.B          #0, D4  
            MOVE.B          #'$',   (A2)+   
            MOVE.W          (A5)+,  D3  * increase word size address and store it in D3 
            CLR.L           D1  * clear d1 to use as a counter  
            MOVE.B          #4, D1     
            JSR             _GET_WORD_VALUE 
            RTS

_PRINT_DATA_REG_1
            CMP.B           #7, D5           * check n > 7
            BGT             _INVALID_OPCODE 
            MOVE.B          #'D',   (A2)+
            ADD.W           #$30,    D5   
            MOVE.B          D5,   (A2)+
            RTS

_PRINT_ADDRESS_REG_1
            CMP.B           #7, D5           * check n > 7
            BGT             _INVALID_OPCODE
            MOVE.B          #'A',   (A2)+
            ADD.W           #$30,    D5   
            MOVE.B          D5,   (A2)+
            RTS

_PRINT_PAREN_ADDRESS_REG_1
            CMP.B           #7, D5           * check n > 7
            BGT             _INVALID_OPCODE
            MOVE.B          #'(',   (A2)+
            MOVE.B          #'A',   (A2)+
            ADD.W           #$30,    D5
            MOVE.B          D5,   (A2)+
            MOVE.B          #')',   (A2)+
            RTS

_PRINT_INCRE_ADDRESS_REG_1
            CMP.B           #7, D5           * check n > 7
            BGT             _INVALID_OPCODE
            MOVE.B          #'(',   (A2)+
            MOVE.B          #'A',   (A2)+
            ADD.W           #$30,    D5
            MOVE.B          D5,   (A2)+
            MOVE.B          #')',   (A2)+
            MOVE.B          #'+',   (A2)+
            RTS

_PRINT_DECRE_ADDRESS_REG_1
            CMP.B           #7, D5           * check n > 7
            BGT             _INVALID_OPCODE
            MOVE.B          #'-', (A2)+
            MOVE.B          #'(', (A2)+
            MOVE.B          #'A', (A2)+
            ADD.W           #$30, D5
            MOVE.B          D5, (A2)+
            MOVE.B          #')', (A2)+
            RTS

_PRINT_WORD
            MOVE.B          #'.', (A2)+
            MOVE.B          #'W', (A2)+
            MOVE.B          #' ', (A2)+
            JMP             (A0)  

_PRINT_LONGWORD
            MOVE.B          #'.', (A2)+
            MOVE.B          #'L', (A2)+
            MOVE.B          #' ', (A2)+
            JMP             (A0) 

_PRINT_BYTE
            MOVE.B          #'.', (A2)+
            MOVE.B          #'B', (A2)+
            MOVE.B          #' ', (A2)+
            JMP             (A0) 
*-----------------------------------------------------------------------------------------------------------------------
* EA2 END
*-----------------------------------------------------------------------------------------------------------------------   

*-----------------------------------------------------------------------------------------------------------------------
* INPUT ERROR HANDLING
*-----------------------------------------------------------------------------------------------------------------------     
_INVALID 
            LEA             INVALID, A1 * print invalid message 
            MOVE.B          #14, D0  
            TRAP            #15 
            BRA             _INPUT_START_ADDR    * go back to obtain starting adr    
    
_INVALID_START_END_ADDR
            LEA             START_END_ADDR_ERROR,  A1  * print invalid message 
            MOVE.B          #14, D0  
            TRAP            #15 
            BRA             _INPUT_START_ADDR     * go back to obatin staring adr 
        
_INVALID_ADDR_ODD
            LEA             EVEN_NUM_ERROR, A1   * print invalid message    
            MOVE.B          #14, D0  
            TRAP            #15 
            BRA             _INPUT_START_ADDR     * go back to obtain starting adr 
*-----------------------------------------------------------------------------------------------------------------------
* INPUT ERROR HANDLING END
*-----------------------------------------------------------------------------------------------------------------------  

*-----------------------------------------------------------------------------------------------------------------------
* CONTROL BRANCHES
*-----------------------------------------------------------------------------------------------------------------------   
*Continue to next page query 
_CONTINUE
            JSR             _PRINT_NEWLINE
            LEA             CONTINUE_READ, A1  
            MOVE.B          #14, D0  
            TRAP            #15 
            *_________ get user input___________    
            MOVE.B          #5, D0  * char at d1    
            TRAP            #15 
            CMP.B           #$0D, D1   * if it is space   
            BEQ             _RESET_COUNTER  
            CMP.B           #$51, D1  * if it is Q    
            BEQ             _RERUN 
            CMP.B           #$71, D1  * if it is q    
            BEQ             _RERUN
            BRA             _CONTINUE   
_RESET_COUNTER 
            MOVE.B          #0, program_counter  * set  counter to 0 
            RTS

*Run disassembler again query
_RERUN
            JSR             _PRINT_NEWLINE
            LEA             RUN_AGAIN, A1     
            MOVE.B          #14, D0  
            TRAP            #15 
            MOVE.B          #5, D0  *Get user input in D1  
            TRAP            #15 
            CMP.B           #$79, D1 *y
            BEQ             _INPUT_START_ADDR
            CMP.B           #$59, D1 *Y
            BEQ             _INPUT_START_ADDR
            CMP.B           #$6E, D1 *n
            BEQ             _FINISH
            CMP.B           #$4E, D1 *N
            BEQ             _FINISH
            BRA             _RERUN *Else repeat query

*Reached end address notification
_REACH_END_ADR
            JSR             _PRINT_NEWLINE
            LEA             REACHED_END, A1
            MOVE.B          #14, D0  
            TRAP            #15 
            BRA             _RERUN
            BRA             _FINISH  

*End program
_FINISH
            JSR             _PRINT_NEWLINE
            LEA             TERMINATE, A1   
            MOVE.B          #14, D0  
            TRAP            #15
*-----------------------------------------------------------------------------------------------------------------------
* CONTROL BRANCHES END
*-----------------------------------------------------------------------------------------------------------------------    

            SIMHALT
        
*-----------------------------------------------------------------------------------------------------------------------
* VARIABLES
*-----------------------------------------------------------------------------------------------------------------------
CR                      EQU     $0D     *   Carriage Return
LF                      EQU     $0A     *   Line Feed
NEWLINE                 DC.B    CR, LF, 0
*Messages
WELCOME                 DC.B    'Welcome to the Disassembler Program', CR, LF
                        DC.B    'Final Project for CSS 422', CR, LF
                        DC.B    '   Authors:', CR, LF
                        DC.B    '       Yang Hu', CR, LF
                        DC.B    '       Matt Johnson', CR, LF
                        DC.B    '       Jun Park', 0
START_ADDR              DC.B    'Please enter start address (word): $', 0
END_ADDR                DC.B    'Please enter end address (word): $', 0
INVALID                 DC.B    'The address you provided is invalid', CR, LF, 0
EVEN_NUM_ERROR          DC.B    'The address you provided is not an even ending number',  CR, LF, 0
START_END_ADDR_ERROR    DC.B    'Your start address is bigger than or equal to the end address', CR, LF, 0
CONTINUE_READ           DC.B    'Press enter to continue disassembling. Press Q or q to end early.', CR, LF, 0
RUN_AGAIN               DC.B    'Run disassembler again? (y or n).', CR, LF, 0
TERMINATE               DC.B    'Ending the program...Bye', CR, LF, 0
REACHED_END             DC.B    'The program reached the end address', CR, LF, 0    
*Storage
user_input              DS.L    1   
start_addr_loc          DS.L    1   *Starting address
end_addr_loc            DS.L    1   *Ending address    
program_counter         DS.L    1   
move_counter            DS.L    1   
program_end             DS.L    1   *Variable to store location where this program ends
*-----------------------------------------------------------------------------------------------------------------------
* VARIABLES END
*-----------------------------------------------------------------------------------------------------------------------

            END             START
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~