*-----------------------------------------------------------
* Title       : 68k Disassembler    
* Written by  : Yang Hu, Matt Johnson, Jun Park
* Date        : 06/06/2020    
* Version     : v1.0
* Description : Final project for CSS 422. Disassembles sets of machine code (see documentation) into human readable code.
*-----------------------------------------------------------

*Disassembler takes memory $1000-$xxxx
    ORG    $1000

START:
*_______Basic Print Out Welcome Message__________  
    MOVE.B  #0, ProgramCounter * added to test sub and end program  
    LEA Mes_Welcome,    A1
    MOVE.B  #13,    D0
    TRAP    #15
    
*_______Get User Input____________________________
Get_Input_Start_ADR
    LEA     Extra_Space,    A1
    MOVE.B  #14,            D0
    TRAP    #15
    CLR.L   D2  
    CLR.L   D3
   
    LEA Mes_Start_Adr,  A1  ; ask start loc
    MOVE.B  #14, D0   
    Trap    #15     
    LEA UserInput,  A1  ;   get user input  
    MOVE.B  #2, D0  
    TRAP    #15 
 
    JSR ConvertInput        
    * check if the address is odd then throw error just read right bit  
    *ANDI.B  #1, D3  
    BTST #0,    D3 * is Even?  
    BNE Invalid_Adr_Not_Even  * Not even then go to invalid        
    
    * Store user Input start address to A5
    MOVE.L  D3, StartLocData
    MOVE.L  StartLocData, A5  
    
*_________Check Start Adr is Even Number__________________

        
Get_Input_End_ADR  
    CLR.L   D2  
    CLR.L   D3  
    
    LEA Mes_End_Adr,    A1  ;   ask ending loc  
    MOVE.B  #14,    D0       
    TRAP    #15 
    
    LEA EndLocData, A1  ;   get user input  
    MOVE.B  #2, D0  
    Trap    #15 
 
    JSR ConvertInput    
    * check if the address is odd then throw error just read right bit 
    BTST    #0, D3  
    BNE Invalid_Adr_Not_Even    
    * Store user Input start address to A6  
    MOVE.L  D3, EndLocData
    MOVE.L  EndLocData, A6  
    LEA     Extra_Space,    A1
    MOVE.B  #14,            D0
    TRAP    #15
    
*________________________________________________________   
*   Compare Starting Address and End Address see if it make sense       
Check_Input_Address
    CLR.L   D2  * clr out before use it 
    CLR.L   D3  * clr out before use it 
    MOVE.L  A5, D2  * move starting adr to d2 to check   
    MOVE.L  A6, D3  * move ending adr to d3 to check    
    CMP.L   D3, D2  * end address is not bigger than starting addr and address same? Error  
    BGE Invalid_Starting_Ending_Adr
    
    *___________Clear All Unnecessary register____________________________  
    JSR     _CLEAR_DN  
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4    
    *____________ End of Clear____________________________________________ 
    
*_______End of User Input Adr______________________________ 
CheckProgramCounter 
    CMP.B   #25,    ProgramCounter  * check program counter 
    BNE Disassemble_Loop        
    CMP.L   A5, A6  
    BEQ REACH_END_ADR 
    JSR ToContinueProgram 
Disassemble_Loop
    CMP.B   #25,    ProgramCounter  
    BEQ FINISH  
    ADD.B   #1, ProgramCounter
    MOVE.B  #0, MoveInstructionCounter
*   Clear Loop  
    JSR     _CLEAR_DN   
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4  
*   Clear Loop  
    JSR Print_Cur_Addr
    LEA ProgramEnd, A2  * A2    store   program end 
    JSR ERASE_A2_MEM
    LEA ProgramEnd, A2  * A2    store   program end
    JSR Disassemble  
    MOVE.B  #$00,   (A2)+   
    LEA ProgramEnd, A1  
    MOVEQ   #13,    D0  
    TRAP    #15 
    * 00000000000000000000000000000000000
    MOVE.B  #0, MoveInstructionCounter  
    *________Before BRA FINISH is for testin purpose_________
    *BRA FINISH  *   FINISH for now for testing purpose  
    *________________________________________________________
       *BRA Disassemble_Loop    
    BRA CheckProgramCounter
ERASE_A2_MEM
    MOVE.L A2, D2
    ADD.L #50, D2
ERASE_A2_LOOP
    CMP.L D2, A2
    BEQ GoBack
    MOVE.B #$FF, (A2)+
    BRA  ERASE_A2_LOOP
*_______Start of reading machine code______________________

Disassemble                     * while A5 is less than A6
        MOVE.L A5, D0
        CMP.L A6, D0
        BGE OUTPUT_RESULT
        CLR.L   D1  
        MOVE.B (A5), D1        * read a byte from from A5, store to D1. This contains opcode
        *valid opcode bits cases: 10-EF
        CMP.W   #$10, D1             
        BLT    INVALID_OPCODE   * invalid, need to move on to the next word
        
        CMP.W  #$3F, D1          * 0001 - 0011 -> -> 10 - 3F -> MOVE, MOVEA            * 
        BLE    _MOVE_MOVEA
        
        CMP.W  #$4F, D1          * 0100 -> 40 - 4F -> MOVEM, LEA, JSR, RTS
        BLE _MOVEM_LEA_JSR_RTS
        
        CMP.W #$6F, D1           * 0110 -> 50 - 5F -> BCC (note it should not be 5F)
        BLE _BXX  
        
        CMP.W #$80, D1           * 60 - 7F invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        CMP.W #$8F, D1           * 1000 -> 80 - 8F -> OR
        BLE _OR
        
        CMP.W #$9F, D1           * 1001 -> 90 - 9F -> SUB
        BLE _SUB
        
        CMP.W #$B0, D1           * A0 - AF invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        CMP.W #$BF, D1           * 1011 -> B0 - BF -> CMP
        BLE _CMP
        
        CMP.W #$CF, D1           * 1100 -> C0- CF -> AND
        BLE _AND
        
        CMP.W #$DF, D1           * 1101 -> D0 - DF -> ADD
        BLE _ADD
        
        CMP.W #$EF, D1           * 1110 -> E0 - EF -> LSL, ASR
        BLE _LSL_ASR
        
        BRA INVALID_OPCODE
        
INVALID_OPCODE                   * skip to the next word
        LEA ProgramEnd, A2  * A2    store   program end
        JSR ERASE_A2_MEM
        LEA ProgramEnd, A2  * A2    store   program end
        MOVE.B #'C', (A2)+
        MOVE.B #'A', (A2)+
        MOVE.B #'N', (A2)+
        MOVE.B #'N', (A2)+
        MOVE.B #'O', (A2)+
        MOVE.B #'T', (A2)+
        MOVE.B #' ', (A2)+
        MOVE.B #'D', (A2)+
        MOVE.B #'E', (A2)+
        MOVE.B #'C', (A2)+
        MOVE.B #'O', (A2)+
        MOVE.B #'D', (A2)+
        MOVE.B #'E', (A2)+
        ADDA #$2, A5
        RTS
        
* for all below methods,      

*___________________________________________________________________________________
* start of get EA
* precondition: A5 points to the first byte of the current machine code, D1 contains the first byte of the command      
*_____________________________________________________________________________________  
_MOVE_MOVEA
    MOVE.B  #'M',   (A2)+   
    MOVE.B  #'O',   (A2)+   
    MOVE.B  #'V',   (A2)+  
    MOVE.B  #'E',   (A2)+ 
    JSR PREPARE_DATA_REG
    CLR.L D0
    MOVE.L D1, D0
    LSR.W #8, D0
    LSR.W #4, D0
    CMP.B #1,   D2
    BNE MOVE_MOVEA_SIZE
    MOVE.B  #'A',   (A2)+

MOVE_MOVEA_SIZE
    LEA MOVE_MOVEA_SRC, A0
    * fixing on the size    
    MOVE.W  D1, D6  * saw that D6 was free      
    ANDI.W  #$3000, D6    
    *CMP.B   #3, D1
    CMP.W   #$3000, D6  
    BEQ     PRINT_WORD
    CMP.W   #$2000, D6  
    *CMP.B   #2, D1
    BEQ     PRINT_LONGWORD
    CMP.B #1,   D2
    BEQ INVALID_OPCODE
    JMP     PRINT_BYTE
    
MOVE_MOVEA_SRC
    JSR PRINT_TAB
    MOVE.L D3, D6
    CMP.W #$4,D4
    BLE TO_EA
IS_SEVEN
    CMP.W #$7,D4
    BNE INVALID_OPCODE
TO_EA
    JSR EA1
    
    MOVE.B  #',',   (A2)+  
    
MOVE_MOVEA_DEST
    JSR PRINT_TAB
    MOVE.L D2, D4      
    MOVE.L D6, D5
    
    CMP.B #$000, D4
    BEQ TO_EA_2 
    	    
    CMP.B #$1, D4
    BEQ TO_EA_2 
       
    CMP.B  #$2, D4
    BEQ TO_EA_2 
       
    CMP.B  #$3, D4
    BEQ TO_EA_2 

    CMP.W #$4, D4
    BEQ TO_EA_2 
    
    CMP.W #$7,D4
    BEQ TO_EA_2 
    
    BRA INVALID_OPCODE
TO_EA_2
   JSR EA1
   *BRA OUTPUT_RESULT
   RTS  

    

*______________________MOVEM_LEA_JSR_RTS____________________    
_MOVEM_LEA_JSR_RTS
    * clear before use  
    CLR.L   D0  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
    MOVE.W  (A5)+,  D2  * load full opcode  
    MOVE.W  D2, D3
       *BEQ _Movem
      CMP.B   #$48, D1 
    BEQ _Movem  
    CMP.W   #$4C, D1  
    BEQ _Movem  

    * check second hex to determine if it is movem or others
    * movem is 1100 or 1000 others are 1110, 1110, and 1111~ xxx1   
    ANDI.W  #$0100, D3    
    CMP.W   #$0100, D3  *   
    BEQ Lea_Jsr_Rts 
    BRA Lea_Jsr_Rts 
    * Then it should be either lea, jsr, rts    
    
*_______________movem instruction____________________________________        
_Movem  
    * so i need to catch the case before it store movem 
    MOVE.B  #'M',   (A2)+   
    MOVE.B  #'O',   (A2)+   
    MOVE.B  #'V',   (A2)+   
    MOVE.B  #'E',   (A2)+   
    MOVE.B  #'M',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    JSR _MovemSize  
    CLR.L   D4  
    MOVE.B  #' ',   (A2)+   
    MOVE.W  D2, D4  
    * check dr to decide wheather m->r or r -> m    
    * basic logic
    * xxxx xXxx, it is the second bit of the 2nd hex bit either 1 or 0  
    ANDI.W  #$0400, D4  
    CMP.W   #$0400, D4  
    BEQ MemoryToRegister    
    CMP.W   #$0000, D4  
    BEQ RegisterToMemory    
    BRA INVALID_OPCODE
    
MemoryToRegister
     * register to memory 010, 100, 111, 111 works else error
    CLR.L   D0  
    CLR.L   D1      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
    CLR.L D6
    MOVE.W  (A5)+, D6
    JSR PRINT_TAB
    MOVE.L D2, D1
    MOVE.L D2, D0
    CLR.L   D2
    JSR PREPARE_DATA
    JSR EA1
    MOVE.L D0, D1
    JSR PREPARE_DATA
    MOVE.W #$FFFF, D7
    CMP.W #2, D4
    BEQ REG_TO_MEM_LIST
    CMP.W #3, D4
    BEQ REG_TO_MEM_LIST
    CMP.W #7, D4
    BEQ REG_TO_MEM_LIST
    BRA INVALID_OPCODE

RegisterToMemory
    * register to memory 010, 100, 111, 111 works else error
    CLR.L   D0  
    CLR.L   D1      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
    CLR.L D6
    MOVE.W  (A5)+, D6
    MOVE.L D2, D0
    MOVE.L D2, D1
    CLR.L   D2
    JSR PREPARE_DATA
    CMP.W #2, D4
    BEQ REG_TO_MEM_LIST
    CMP.W #4, D4
    BEQ REG_TO_MEM_LIST_PRE
    CMP.W #7, D4
    BEQ REG_TO_MEM_LIST
    BRA INVALID_OPCODE
    
REG_TO_MEM_LIST
    JSR PRINT_TAB
    *Use d6 for list
    CMP.W #0, D6       
    BEQ INVALID_OPCODE

    MOVE.B D6, D5
    LSR.W #8, D6
    MOVE.L #0, D1
    MOVE.L #$FFFF, D2
    MOVE.L #$FFFF, D3
    
REG_TO_MEM_ALOOP
    LEA REG_TO_MEM_ALOOP, A0
    CMP.B  #8, D1
    BEQ REG_TO_MEM_ALOOP_PRINT
    LSR.B #1, D6
    BCS CHECK_D2D3
    ADD.B #1, D1
    BRA REG_TO_MEM_ALOOP
CHECK_D2D3
    CMP.W #$FFFF, D2
    BEQ SET_D2
SET_D3
    MOVE.W D1, D3
    ADD.B #1, D1
    JMP (A0)
SET_D2    
    MOVE.W D1, D2
    ADD.B #1, D1
    JMP (A0) 
    
REG_TO_MEM_ALOOP_PRINT
    CMP.W #$FFFF, D2
    BEQ PREPARE_REG_TO_MEM_DLOOP
    MOVE.B  #'A',   (A2)+
    ADD.W #$30, D2   
    MOVE.B  D2,   (A2)+
    CMP.W #$FFFF, D3
    BEQ PREPARE_REG_TO_MEM_DLOOP1
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W #$30, D3   
    MOVE.B  D3,   (A2)+
    BRA PREPARE_REG_TO_MEM_DLOOP1
PREPARE_REG_TO_MEM_DLOOP1
    MOVE.B  #'/',   (A2)+        
PREPARE_REG_TO_MEM_DLOOP
    MOVE.L #0, D1
    MOVE.L #$FFFF, D2
    MOVE.L #$FFFF, D3
REG_TO_MEM_DLOOP
    LEA REG_TO_MEM_DLOOP, A0
    CMP.B  #8, D1
    BEQ REG_TO_MEM_DLOOP_PRINT
    LSR.B #1, D5
    BCS CHECK_D2D3
    ADD.B #1, D1
    BRA REG_TO_MEM_DLOOP
REG_TO_MEM_DLOOP_PRINT
    CMP.W #$FFFF, D2
    BNE HAS_D
    SUB.L #1, A2
    MOVE.B  #' ',   (A2)
    BRA PRE_REG_TO_MEM_EA
HAS_D
    MOVE.B  #'D',   (A2)+
    ADD.W #$30, D2   
    MOVE.B  D2,   (A2)+
    CMP.W #$FFFF, D3
    BEQ PRE_REG_TO_MEM_EA
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'D',   (A2)+
    ADD.W #$30, D3   
    MOVE.B  D3,   (A2)+
PRE_REG_TO_MEM_EA
    CMP.W #$FFFF, D7
    BEQ GoBack
    
REG_TO_MEM_EA
    MOVE.L D0, D1
    JSR PRINT_TAB
    JSR PREPARE_DATA
    JSR EA1
    RTS    

REG_TO_MEM_LIST_PRE
    JSR PRINT_TAB
    *Use d6 for list
    CMP.W #0, D6
    BEQ INVALID_OPCODE
    MOVE.L #0, D1
    MOVE.L #$FFFF, D2
    MOVE.L #$FFFF, D3
REG_TO_MEM_ALOOP_PRE
    LEA REG_TO_MEM_ALOOP_PRE, A0
    CMP.B  #8, D1
    BEQ REG_TO_MEM_ALOOP_PRINT_PRE
    LSL.B #1, D6
    BCS CHECK_D2D3_PRE
    ADD.B #1, D1
    BRA REG_TO_MEM_ALOOP_PRE
CHECK_D2D3_PRE
    CMP.W #$FFFF, D2
    BEQ SET_D2_PRE
SET_D3_PRE
    MOVE.W D1, D3
    ADD.B #1, D1
    JMP (A0)
SET_D2_PRE    
    MOVE.W D1, D2
    ADD.B #1, D1
    JMP (A0) 
    
REG_TO_MEM_ALOOP_PRINT_PRE
    CMP.W #$FFFF, D2
    BEQ PREPARE_REG_TO_MEM_DLOOP_PRE
    MOVE.B  #'A',   (A2)+
    ADD.W #$30, D2   
    MOVE.B  D2,   (A2)+
    CMP.W #$FFFF, D3
    BEQ PREPARE_REG_TO_MEM_DLOOP1_PRE
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W #$30, D3   
    MOVE.B  D3,   (A2)+
    BRA PREPARE_REG_TO_MEM_DLOOP1_PRE
PREPARE_REG_TO_MEM_DLOOP1_PRE
    MOVE.B  #'/',   (A2)+        
PREPARE_REG_TO_MEM_DLOOP_PRE
    MOVE.L #0, D1
    MOVE.L #$FFFF, D2
    MOVE.L #$FFFF, D3
REG_TO_MEM_DLOOP_PRE
    LEA REG_TO_MEM_DLOOP_PRE, A0
    CMP.B  #8, D1
    BEQ REG_TO_MEM_DLOOP_PRINT_PRE
    LSL.W #1, D6
    BCS CHECK_D2D3_PRE
    ADD.B #1, D1
    BRA REG_TO_MEM_DLOOP_PRE
REG_TO_MEM_DLOOP_PRINT_PRE
    CMP.W #$FFFF, D2
    BNE HAS_D_PRE
    SUB.L #1, A2
    MOVE.B  #' ',   (A2)
    BRA REG_TO_MEM_EA
HAS_D_PRE
    MOVE.B  #'D',   (A2)+
    ADD.W #$30, D2   
    MOVE.B  D2,   (A2)+
    CMP.W #$FFFF, D3
    BEQ REG_TO_MEM_EA
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'D',   (A2)+
    ADD.W #$30, D3   
    MOVE.B  D3,   (A2)+
    BRA REG_TO_MEM_EA

                
* basic logic
* its always going to be either 11xx or 10xx    
* the second bit is the one decide the size 
* compare with 0040 and 0000 then its word 0100 then its lw 
_MovemSize  
    MOVE.W  D2, D4  * get data stored in address
    ANDI.W  #$0040, D4   * prepare for compare
    CMP.W  #$0040,  D4    
    BEQ Movem_LongWord_Size 
    MOVE.B  #'W',   (A2)+  
    RTS      
Movem_LongWord_Size 
    MOVE.B  #'L',   (A2)+   
    RTS    
    
Lea_Jsr_Rts
    MOVE.W  D2, D4  
    ANDI.W  #$00C0, D4  
    CMP.W   #$00C0, D4  
    BEQ LEA 
    CMP.W   #$0080, D4  
    BEQ JSR 
    CMP.W   #$0040, D4    
    BEQ RTS 
    *BRA JSR_RTS     
JSR 
    CLR.L   D4  
    CLR.L   D3  
    CLR.L   D5  
    MOVE.W  D2, D4  * store for basic check validation    
    ANDI.W  #$00F0, D4    * perform test with 1111 on third hex, whatever it matches with 1 result out 1    
    CMP.W   #$0090, D4    *  already 10xx, 10 part is confirm, to obtain retain two digits 01 then 010  
    BEQ Print_JSR_010   
    CLR.L   D4  * if not same then reset D4 and store value again for validation check  
    MOVE.W  D2, D4      * store it in cleared D4    
    ANDI.W  #$00FF, D4    * perform 1111 1111   
    CMP.W   #$00B8, D4    *  already 10xx xxxx is confirm, to obtain xx xxxx check with 111 000 then it is 111 000    
    BEQ Print_JSR_111_000   
    CLR.L   D4  * if not same then reste D4 and store value again for validation check  
    MOVE.W  D2, D4  * store it in cleared D4    
    ANDI.W  #$00FF, D4    * same logic  
    CMP.W   #$00B9, D4    * 10xx xxxx -> check x bits either 111 001 then 111 001     
    BEQ Print_JSR_111_001   
    * rest its invalid   
Print_JSR_010   
    MOVE.B  #'J',   (A2)+   * push it in this program ending memory    
    MOVE.B  #'S',   (A2)+   * push it in this program ending memory
    MOVE.B  #'R',   (A2)+   * push it in this program ending memory
    MOVE.B  #' ',   (A2)+   * push it in this program ending memory
    * shift 3 bits to check if it is 010    
    CLR.L   D4  * clear d4
    CLR.L   D3  * clear d3 
    MOVE.W  D2, D3  
    ROR.W   #3, D3    * shift register field to the front to make mode is the last 3 bits   
    MOVE.W  D3, D4  
    ANDI.W  #$0002, D4 * to check xxxx xxxx xx01 ?xxx, ? should be 0    
    CMP.W  #$0002, D4       * check if last two bits are 10 if not invalid not 010  
    BNE INVALID_OPCODE * if not just invalid    
    CLR.L   D4  * after check clear d4  
    MOVE.W  D2, D4  
    ROR.W   #3, D4  * shift 3 bits to the end from front just to get prepare for EA_List  
    JSR EA_List_010  
    RTS 
Print_JSR_111_000   
    MOVE.B  #'J',   (A2)+   * push it in this program ending memory 
    MOVE.B  #'S',   (A2)+   * push it in this program ending memory 
    MOVE.B  #'R',   (A2)+   * push it in this program ending memory 
    MOVE.B  #' ',   (A2)+   * push it in this program ending memory 
    CLR.L   D4              * clear d4  
    MOVE.W  D2, D4          * obtain value  
    ROR.W   #3, D4          * shift 3 bits to the end from front just to get prepare for EA_List
    JSR EA_List_111 
    RTS 
Print_JSR_111_001   
    MOVE.B  #'J',   (A2)+   * push it in this program ending memory 
    MOVE.B  #'S',   (A2)+   * push it in this program ending memory 
    MOVE.B  #'R',   (A2)+   * push it in this program ending memory 
    MOVE.B  #' ',   (A2)+   * push it in this program ending memory 
    CLR.L   D4              * clear d4 
    MOVE.W  D2, D4          * obtain value
    ROR.W   #3, D4          * shift 3 bits to the end from front just to get prepare for EA_List
    JSR EA_List_111 
    RTS 
*_________________RTS_______________________________
RTS
    CLR.L   D4  
    MOVE.W  D2, D4  
    CMP.W   #$4E75, D4  * just print RTS    
    BEQ Print_RTS  
    * Below added for invalid_________________
    CMP.W   #$4E75, D4  * compare directly  
    BNE INVALID_OPCODE
    * not equal then simply throw error 
Print_RTS
    MOVE.B  #'R',           (A2)+     
    MOVE.B  #'T',           (A2)+      
    MOVE.B  #'S',           (A2)+   
    RTS 
*______________RTS End_____________________________        
LEA 
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D4  
    MOVE.W  D2, D3  
    * adding for invalid things 
    ROR.W   #3, D3    
    ANDI.W  #$0007, D3
    CMP.W   #$0000, D3  * catching Dn case invalid    
    BEQ INVALID_OPCODE    
    CMP.W   #$0001, D3  * caching An case invalid   
    BEQ INVALID_OPCODE  
    CMP.W   #$0003, D3  * catching (An)+ case invalid   
    BEQ INVALID_OPCODE    
    CMP.W   #$0004, D3  * catching -(An) case invalid   
        BEQ INVALID_OPCODE  
    *____________________Invalid case done________________________
    CLR.L   D3 * edge case seems to be clear so reset address    
    MOVE.W  D2, D3  
    *  end of addling for invalid things    
    
    ROR.W   #3, D3  * shift 3 to obtain src mode   
    MOVE.W  D3, D5  
    MOVE.W  D3, D4  * store in D4 to use function EA_LIST and REGISTER_LISTS    
    ANDI.W  #$0007, D3        
    CMP.W   #$0002, D3      
    BEQ Print_LEA   
Print_LEA   
    MOVE.B  #'L',   (A2)+   * push it in this program ending memory
    MOVE.B  #'E',   (A2)+   * push it in this program ending memory
    MOVE.B  #'A',   (A2)+   * push it in this program ending memory
    MOVE.B  #' ',   (A2)+   * push it in this program ending memory
    JSR EA_Lists    
    MOVE.B  #',',   (A2)+    * push it in this program ending memory
    CLR.L   D4               * clear out d4 
    MOVE.W  D2, D4           * obtain data stored in the memory 
    ROL.L   #4, D4           *  prepare to just directly go to EA_List_001, for an register 
    JSR EA_List_001 * go to A
    RTS 
*______________________END OF LEA JSR RTS___________________
    
*____________________BCC BLE BGT____________________________    
_BXX    
* clear out before use
    CLR.L   D0  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
* clear out before use
    MOVE.W  (A5)+,   D2  * load full opcode BCC, BGT, BLE same so D2 has 006x      
    MOVE.W  D2, D6        * transfer clean data to d6   
    ROL.W   #4, D6          * shift 4 (condition in front)  

    MOVE.W  D6, D5    
    ROL.W   #4, D6        * clear out 00s just to check condition   
    MOVE.W  D6, D5        * store it for safety 
    ANDI.W  #$000F, D6     * check condition    
    CMP.W   #$F,    D6     * 1111 then BLE      
    BEQ _BLE
    CMP.W   #$E,    D6     * 1110 then BGT  
    BEQ _BGT
    CMP.W   #$4,    D6     * 0100 then BCC   
    BEQ _BCC
    BRA INVALID_OPCODE      * else invalid  
 
        
_BCC
    MOVE.B  #'B',   (A2)+   * Store BCC at the end of this program  
    MOVE.B  #'C',   (A2)+   
    MOVE.B  #'C',   (A2)+  
    MOVE.B  #' ',   (A2)+   * little space
    MOVE.B  #' ',   (A2)+   * little space
    BRA BXX_Displacement 
    
_BLE
    MOVE.B  #'B',   (A2)+   * Store BLE at the end of this program 
    MOVE.B  #'L',   (A2)+   
    MOVE.B  #'E',   (A2)+  
    MOVE.B  #' ',   (A2)+   * little space
    MOVE.B  #' ',   (A2)+   * little space
    BRA  BXX_Displacement   
        
_BGT
    MOVE.B  #'B',   (A2)+   * Store BGT at the end of this program 
    MOVE.B  #'G',   (A2)+   
    MOVE.B  #'T',   (A2)+  
    MOVE.B  #' ',   (A2)+   * little space
    MOVE.B  #' ',   (A2)+    * little space
    BRA BXX_Displacement

BXX_Displacement    
    MOVE.B  #0, D0  *   set up counter 0 to 8, its for byte 
    MOVE.B  #8, D3  *   counter max  
    MOVE.W  D2, D6  *   Load full memory 
    MOVE.L  A5, D5  *   Load current starting adr from user 
    ANDI.W  #$00FF, D6  *   00XX   
    CMP.W   #$FF,   D6  *   if  FF then it should be 16 bits displacement   
    BEQ BXX_DISPLACEMENT_LONG      
    CMP.W   #$00,   D6  *   if 00 then it should be 8bit displacement (word)    
    BEQ BXX_DISPLACEMENT_WORD 
    BRA BXX_DISPLACEMENT_8Bit   *   rest of them are 8 bit  
  
   
BXX_DISPLACEMENT_8Bit
    ROL.B   #1, D6  * used 6450 -> xx50 -> 0101 0000 -> 1010 xxxx   
    BCS BXX_Last_Ones_Convert   *   Convert 1s  
    ADDI.B  #1, D6  
    BRA BXX_TwosComplement_Cal
    
BXX_Last_Ones_Convert   
    SUBI.B  #1, D6  
    BRA BXX_TwosComplement_Cal
          
BXX_TwosComplement_Cal   
    ADDI.B  #1, D0  *   Increase counter set up at displacement  
    CMP.B   D0, D3  *   Check if it is last loop        
    BEQ BXX_TwosComplement_Last_Add     *   complement done go to add   
    CMP.B   #8, D3  *   Check if the size is for 8bit   
    BEQ BXX_DISPLACEMENT_8Bit 
    CMP.B   #16,    D3  * Check for the 16 bits disp
    BEQ BXX_Complement_Word
    BRA BXX_TwosComplement_Last_Add 
    
BXX_DISPLACEMENT_WORD
    MOVE.B  #16,    D3  * set up counter for word   16 bits 
    MOVE.W  (A5)+,  D6  * store the next memory for displacement next word       
    MOVE.W  D6, D1  *   copy next word to d1 to test    
    ANDI.W  #$8000, D1  *   Set up to test if it has to go back
    CMP.W   #$8000, D1  
    BNE BXX_DISPLACEMENT_WORD_JUST_PRINT    * Not equal then just print
BXX_Complement_Word    
    ROL.W   #1, D6  *   check word size bit 
    BCS BXX_Last_Ones_Convert   *   convert 1s  
    ADDI.B  #1, D6  *   these are 0s    
    BRA BXX_TwosComplement_Cal  
    
BXX_DISPLACEMENT_WORD_JUST_PRINT
    ADD.W   D6, D5  * just print (add d6 to current adr)
    BRA Display_BXX *   go to display   
    
BXX_DISPLACEMENT_LONG   
    * will be implemented
    MOVE.B  #32,    D3  * set up counter for longword 32 bit    
    MOVE.L  (A5)+,  D6  * store next longword size memory value 
    MOVE.L  D6, D1  * copy  next longword to d1 to test 
    ANDI.L  #$80000000, D1  *   Set up to test if it has to go back  
    CMP.L   #$80000000,    D1  
    BNE BXX_DISPLACEMENT_LONG_JUST_PRINT   * Not equal then just print
BXX_Complement_Long     
    ROL.W   #1, D6  *   check word size bit 
    BCS BXX_Last_Ones_Convert   *   convert 1s  
    ADDI.B  #1, D6  *   these are 0s    
    BRA BXX_TwosComplement_Cal      
 
BXX_DISPLACEMENT_LONG_JUST_PRINT    
        ADD.L   D6, D5  *   just print (Add d6 to current adr)  
        BRA Display_BXX  
BXX_TwosComplement_Last_Add   
    ADDI.W  #$1,    D6  *   Add 1 at the end to the bit   
    SUB.L   D6, D5  
   
Display_BXX    
    CMP.L   #$FFFF, D5  *   check if the size is for longword size
    BGT Display_BXX_Long_Word
    MOVE.B  #4, D3  
    CLR.L   D7  
    JSR Ascii_Convert_BXX   
    RTS 
Display_BXX_Long_Word
     
Ascii_Convert_BXX
    ROL.W   #4, D5  
    MOVE.L  D5, D4  
    ANDI.L  #$0000000F, D4  *   just compare last 4 bits
    CMPI.B  #$09,   D4      *   check is number or letter      
    BLE  IS_NUM 
    ADDI.B  #$37,   D4      * is letter 
    BRA IS_LET   
IS_NUM  
    ADDI.B  #$30,   D4      * is nubmer 
    BRA IS_LET  
IS_LET  
    ADDI.B  #1, D7    
    MOVE.B  D4, (A2)+   
    CMP.B   D3, D7    
    BLT Ascii_Convert_BXX
    RTS

*___________________END OF B brothers__________________________ 

*-----------------------------------------------------------------------------------------------------------------------
* ADD
*-----------------------------------------------------------------------------------------------------------------------
_ADD
    MOVE.B  #'A',   (A2)+  
    MOVE.B  #'D',   (A2)+   
    MOVE.B  #'D',   (A2)+   
    MOVE.W  (A5)+,   D2
    MOVE.W  D2, D6
    ANDI.W  #$01C0, D6   
    CMP.W   #$0000, D6
    BEQ _B_EA_DN     
    CMP.W   #$0040, D6  
    BEQ _W_EA_DN 
    CMP.W   #$0080,  D6      
    BEQ _L_EA_DN
    CMP.W   #$0100, D6  
    BEQ _B_DN_EA 
    CMP.W   #$0140, D6  
    BEQ _W_DN_EA 
    CMP.W   #$0180, D6  
    BEQ _L_DN_EA 
    BRA _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* ADD END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* AND
*-----------------------------------------------------------------------------------------------------------------------
_AND
    MOVE.B  #'A',   (A2)+  
    MOVE.B  #'N',   (A2)+   
    MOVE.B  #'D',   (A2)+   
    MOVE.W  (A5)+,   D2
    MOVE.W  D2, D6
    ANDI.W  #$01C0, D6
    CMP.W   #$0000, D6 
    BEQ     _B_EA_DN  
    CMP.W   #$0100, D6  
    BEQ     _B_DN_EA
    CMP.W   #$0040, D6  
    BEQ     _W_EA_DN 
    CMP.W   #$0140, D6  
    BEQ     _W_DN_EA
    CMP.W   #$0080,  D6      
    BEQ     _L_EA_DN  
    CMP.W   #$0180, D6  
    BEQ     _L_DN_EA
    BRA     _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* AND END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* CMP
*-----------------------------------------------------------------------------------------------------------------------
_CMP
    MOVE.B  #'C',   (A2)+  
    MOVE.B  #'M',   (A2)+   
    MOVE.B  #'P',   (A2)+
    MOVE.W  (A5)+,   D2
    MOVE.W  D2, D6
    ANDI.W  #$01C0, D6
    CMP.W   #$0000, D6 
    BEQ     _B_EA_DN  
    CMP.W   #$0040, D6  
    BEQ     _W_EA_DN 
    CMP.W   #$0080,  D6      
    BEQ     _L_EA_DN  
    BRA     _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* CMP END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* OR
*-----------------------------------------------------------------------------------------------------------------------
_OR
    MOVE.B  #' ',   (A2)+  
    MOVE.B  #'O',   (A2)+   
    MOVE.B  #'R',   (A2)+   
    MOVE.W  (A5)+,   D2
    MOVE.W  D2, D6
    ANDI.W  #$01C0, D6
    CMP.W   #$0000, D6 
    BEQ     _B_EA_DN  
    CMP.W   #$0100, D6  
    BEQ     _B_DN_EA
    CMP.W   #$0040, D6  
    BEQ     _W_EA_DN 
    CMP.W   #$0140, D6  
    BEQ     _W_DN_EA
    CMP.W   #$0080,  D6      
    BEQ     _L_EA_DN  
    CMP.W   #$0180, D6  
    BEQ     _L_DN_EA
    BRA     _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* OR END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* SUB
*-----------------------------------------------------------------------------------------------------------------------
_SUB
    MOVE.B  #'S',   (A2)+
    MOVE.B  #'U',   (A2)+
    MOVE.B  #'B',   (A2)+
    MOVE.W  (A5)+,   D2    
    MOVE.W  D2, D6
    ANDI.W  #$01C0, D6  
    CMP.W   #$0000, D6
    BEQ _B_EA_DN     
    CMP.W   #$0040, D6  
    BEQ _W_EA_DN 
    CMP.W   #$0080,  D6      
    BEQ _L_EA_DN
    CMP.W   #$0100, D6  
    BEQ _B_DN_EA 
    CMP.W   #$0140, D6  
    BEQ _W_DN_EA 
    CMP.W   #$0180, D6  
    BEQ _L_DN_EA 
    BRA _ELSE
*-----------------------------------------------------------------------------------------------------------------------
* SUB END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* GENERAL SUBROUTINES
*-----------------------------------------------------------------------------------------------------------------------
*Clear all 8 data registers
_CLEAR_DN
    CLR.L   D0
    CLR.L   D1
    CLR.L   D2
    CLR.L   D3
    CLR.L   D4
    CLR.L   D5
    CLR.L   D6
    CLR.L   D7
    RTS

*Push '.B' into output
_B
    MOVE.B  #'.',       (A2)+
    MOVE.B  #'B',       (A2)+
    MOVE.B  #' ',       (A2)+
    MOVE.B  #' ',       (A2)+
    RTS

*Push '.W' into output
_W
    MOVE.B  #'.',       (A2)+
    MOVE.B  #'W',       (A2)+
    MOVE.B  #' ',       (A2)+
    MOVE.B  #' ',       (A2)+
    RTS

*Push '.L' into output
_L
    MOVE.B  #'.',       (A2)+
    MOVE.B  #'L',       (A2)+
    MOVE.B  #' ',       (A2)+
    MOVE.B  #' ',       (A2)+
    RTS

_ELSE

*General operand subroutine for '.B' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_B_DN_EA
    JSR                 _B
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    MOVE.B  #',',       (A2)+ 
    JSR                 Calculate_EA_Mode
    RTS

*General operand subroutine for '.B' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_B_EA_DN
    JSR                 _B
    JSR                 Calculate_EA_Mode
    MOVE.B  #',',       (A2)+ 
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    RTS

*General operand subroutine for '.W' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_W_DN_EA
    JSR                 _W
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    MOVE.B  #',',       (A2)+ 
    JSR                 Calculate_EA_Mode
    RTS

*General operand subroutine for '.W' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_W_EA_DN
    JSR                 _W
    JSR                 Calculate_EA_Mode
    MOVE.B  #',',       (A2)+ 
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    RTS

*General operand subroutine for '.L' and Dn,<ea>
*Used by: ADD, AND, CMP, OR, SUB
_L_DN_EA
    JSR                 _L
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    MOVE.B  #',',       (A2)+ 
    JSR                 Calculate_EA_Mode
    RTS

*General operand subroutine for '.L' and <ea>,Dn
*Used by: ADD, AND, CMP, OR, SUB
_L_EA_DN
    JSR                 _L
    JSR                 Calculate_EA_Mode
    MOVE.B  #',',       (A2)+ 
    MOVE.B  #'D',       (A2)+
    MOVE.W  D2,         D4  
    ANDI.W  #$0E00,     D4
    LSR.W   #4,         D4
    LSR.W   #4,         D4 
    LSR.W   #1,         D4  
    MOVE.W  D4,         D5
    MOVE.W  D4,         D3
    ANDI.W  #$0007,     D4
    JSR                 Register_Lists
    RTS
*-----------------------------------------------------------------------------------------------------------------------
* GENERAL SUBROUTINES END
*-----------------------------------------------------------------------------------------------------------------------

*-----------------------------------------------------------------------------------------------------------------------
* EA
*-----------------------------------------------------------------------------------------------------------------------
* Basic idea
* 000 to 110 so, need to compare with three bits
* Shift until the the Mode in EA is the last bit    
* Simply check the shifted last 3 bit (mode)
*  000 and 111 -> 000
*  001 and 111 - > 001
*  010 and 111 -> 010 etc etc 
Calculate_EA_Mode   
    MOVE.W  D2, D3  * move data value to d3 for shifting purpose (original data)    
    ROL.W   #4, D3  * Shift 4   Goal is to get EA MODE  
    ROL.W   #3, D3  * Shift 3  
    ROL.W   #3, D3  * Shift 3   
    ROL.W   #3, D3  * Shift 3     
    MOVE.W  D3, D4  *  Save shifted value just for safe   
    ANDI.W  #$0007, D3  * check last 3 bits which is mode it is    
    JSR  EA_Lists  
    RTS 
*__________________________EA MODE Lists_________________________________________   
EA_Lists
    CMP.W   #$000,  D3  
    BEQ EA_List_000 
    
    CMP.W   #$001,  D3  
    BEQ EA_List_001 
   
    CMP.W   #$010,  D3  
    BEQ EA_List_010 
    
    CMP.W   #$011,  D3  
    BEQ EA_List_011 
    
    CMP.W   #$100,  D3  
    BEQ EA_List_100 
    
    CMP.W   #$101,  D3  
    BEQ EA_List_101 
    
    CMP.W   #$110,  D3  
    BEQ EA_List_110 
    
    CMP.W   #$111,  D3  
    BEQ EA_List_111 
    
    *------Direct access----  
    CMP.W   #0, D3  
    BEQ EA_List_000   
   
    CMP.W   #1, D3  
    BEQ EA_List_001
 
    CMP.W   #2, D3  
    BEQ EA_List_010 
    
    CMP.W   #3, D3  
    BEQ EA_List_011 
    
    CMP.W   #4, D3  
    BEQ EA_List_100 
    
    CMP.W   #5, D3  
    BEQ EA_List_101 
    
    CMP.W   #6, D3  
    BEQ EA_List_110 
    
    CMP.W   #7, D3  
    BEQ EA_List_111 
    
    RTS *  RTS for now  

EA_List_000 
    MOVE.B  #'D',   (A2)+   
    * will reset to whatever it was so the last 3 bit is Register   
    *  MOVE.W  D3, D4  * copy the value for safety shift   
    ROL.W   #3, D4  * D4 will contains the orignial value   
    MOVE.W  D4, D3  
    ANDI.W  #$0007, D4  *   Check last 3 bits (register)    
    JSR Register_Lists  
    RTS 

EA_List_001
    MOVE.B  #'A',   (A2)+   * push it in this program ending memory
    ROL.W   #3, D4          * obtain original data    
    MOVE.W  D4, D3          * store it for safety 
    ANDI.W  #$0007, D4      *  use AND logic 111 to obtain register ea
    JSR Register_Lists  
    RTS 
    
EA_List_010
    MOVE.B  #'(',   (A2)+   * push it in this program ending memory
    MOVE.B  #'A',   (A2)+   * push it in this program ending memory
    ROL.W   #3, D4          * obtain original data
    MOVE.W  D4, D3          * store it for safety
    ANDI.W  #$0007, D4      *  use AND logic 111 to obtain register ea
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   * push it in this program ending memory
    RTS 
    
EA_List_011
    MOVE.B  #'(',   (A2)+   * push it in this program ending memory
    MOVE.B  #'A',   (A2)+   * push it in this program ending memory
    ROL.W   #3, D4          * obtain original data
    MOVE.W  D4, D3          * store it for safety
    ANDI.W  #$0007, D4      *  use AND logic 111 to obtain register ea
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   * push it in this program ending memory
    MOVE.B  #'+',   (A2)+   * push it in this program ending memory
    RTS 
    
EA_List_100
    MOVE.B  #'-',   (A2)+   * push it in this program ending memory
    MOVE.B  #'(',   (A2)+   * push it in this program ending memory
    MOVE.B  #'A',   (A2)+   * push it in this program ending memory
    ROL.W   #3, D4          * obtain original data
    MOVE.W  D4, D3          * store it for safety
    ANDI.W  #$0007, D4      *  use AND logic 111 to obtain register ea
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   * push it in this program ending memory
    RTS 

EA_List_101
    BRA INVALID_OPCODE      * just invalid  

EA_List_110
    BRA INVALID_OPCODE      * just invalid    
    
EA_List_111    
    ROL.W   #3, D4      * obtain original data     
    MOVE.W  D4, D3      * store it for safety   
    ANDI.W  #$0007, D4  *  use AND logic 111 to obtain register ea  
    JSR Register_Lists   
    RTS  

*______________________ Lists of Registers________________________________________________  
Register_Lists
    CMP.W   #$0000, D4  
    BEQ Resgister_000   
    CMP.W   #$0001, D4  
    BEQ Register_001
    CMP.W   #$0010, D4  
    BEQ Register_010    
    CMP.W   #$0011, D4  
    BEQ Register_011    
    CMP.W   #$0100, D4  
    BEQ Register_100    
    CMP.W   #$0101, D4  
    BEQ Register_101    
    CMP.W   #$0110, D4  
    BEQ Register_110    
    CMP.W   #$0111, D4  
    BEQ Register_111    
*____________ Direct Access____________________________
    CMP.W   #1, D4
    BEQ   Register_001
    CMP.W   #2, D4  
    BEQ Register_010
    CMP.W   #3, D4  
    BEQ Register_011   
    CMP.W   #4, D4  
    BEQ Register_100    
    CMP.W   #5, D4  
    BEQ Register_101    
    CMP.W   #6, D4  
    BEQ Register_110    
    CMP.W   #7, D4  
    BEQ Register_111     
Resgister_000
    MOVE.W  D3, D4      * obtain original value to D4   
    ROL.W   #8, D4      * shift to gain register      
    ROL.W  #5, D4       * shift to gain register    
    ANDI.W  #$0007, D4  * prepare to compare with 7 (111)   
    CMP.B   #$7,    D4  
    BNE Just_Zero       * not equal just print 0    
    MOVE.B  #0, D4      *   set up counter 0 at d4  
    MOVE.B  #'$',   (A2)+       * push it in this program ending memory 
    MOVE.W  (A5)+,  D3  * increase word size address and store it in D3 
    CLR.L   D1          * clear d1 to use as a counter  
    MOVE.B  #4, D1      * set up counter at d1  
    JSR GetWord_Value   
    RTS 
    
GetWord_Value
    * get the first letter it is stored in D3   
    ROL.W   #4, D3  
    MOVE.L  D3, D7  
    ANDI.L  #$0000000F, D7     
    CMPI.B  #$09,   D7      
    BLE Number_Convert_Word_Size      
    ADDI.B  #$37,   D7      * (letter)  
Letter_Convert_Word_Size    
    ADDI.B  #1, D4  * increase counter    
    MOVE.B  D7, (A2)+   * push the char into  end addres    
    CMP.B  D1,  D4  * compare count 
        BLT GetWord_Value   * less go back  
        RTS 
Number_Convert_Word_Size  
    ADDI.B  #$30,   D7  * add 30 ascii stuffs  (num)     
    BRA Letter_Convert_Word_Size    
    
Just_Zero   
    MOVE.B  #'0',    (A2)+  * push it in this program ending memory
    RTS   
      
Register_001    
    MOVE.W  D3, D4  * get the value of memory again  form is regi opmode ea mode ea regi    
    ROL.W   #8, D4  *  shift so the form now    
    ROL.W   #5, D4  * shift to get register value   
    ANDI.W  #$0007, D4    * do AND 111 to obtain register   
    CMP.B   #$7,    D4    *  not equal to 111 then its just one 
    BNE Just_One
    MOVE.B  #0, D4          * set counter 0 at d4   
    MOVE.B  #'$',   (A2)+   * push it in this program ending memory
    MOVE.L  (A5)+,  D3  *   increase long word size address 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #8, D1          * set counter at d1 (8 cause 8 digit longword)  
    JSR GetLongword_Value   
    RTS  
    
*Same logic applies with word function located at above  
GetLongword_Value
    ROL.L   #4, D3    
    MOVE.L  D3, D7  
    ANDI.L  #$0000000F, D7  
    CMPI.B  #$09,   D7  
    BLE Number_Convert_Longword_Size    
    ADDI.B  #$37,   D7  
Letter_Convert_Longword_Size    
    ADDI.B  #1, D4  
    MOVE.B  D7, (A2)+   
    CMP.B   D1, D4  
    BLT GetLongword_Value   
    RTS 
Number_Convert_Longword_Size    
    ADDI.B  #$30,   D7  
    BRA Letter_Convert_Longword_Size    

Just_One           
    MOVE.B  #'1',   (A2)+      * push it in this program ending memory
    RTS 
    
Register_010
    MOVE.B  #'2',   (A2)+      * push it in this program ending memory
    RTS 
Register_011
    MOVE.B  #'3',   (A2)+      * push it in this program ending memory
    RTS 
Register_100    
    MOVE.W  D3, D4  
    ROL.W   #8, D4          * shift so the form now 
    ROL.W  #5, D4           * shift to get register value
    ANDI.W  #$0007, D4      * do AND 111 to obtain register
    CMP.B   #$7,    D4      *  not equal to 111 then its just four  
    BNE Just_Four   
    MOVE.B  #0, D4          *  set up counter 0 at d4   
    MOVE.B  #'#',   (A2)+   * push it in this program ending memory
    MOVE.B  #'$',   (A2)+   * push it in this program ending memory
    
    MOVE.W  D3, D7  * to determine the size to decide long or word immediate data   
    ROL.W   #4, D7  
    ROL.W   #3, D7  
    ROL.W   #3, D7  
    ANDI.W  #$0007, D7  * get opmode    
    CMP.W   #$0002, D7   
    BEQ    Longword_100 
    CMP.W   #$0006, D7  
    BEQ Longword_100    
    BRA Word_100    
    RTS 
Longword_100    
    CLR.L   D7  
    MOVE.L  (A5)+,  D3 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #8, D1  
    JSR GetLongword_Value
    RTS 
Word_100
    MOVE.W  (A5)+,  D3  * increase word size address and store it in D3 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #4, D1   
    JSR GetWord_Value   
    RTS 

Just_Four
    MOVE.B  #'4',   (A2)+   * push it in this program ending memory
    RTS 

Register_101
    MOVE.B  #'5',   (A2)+   * push it in this program ending memory
    RTS 
Register_110
    MOVE.B  #'6',   (A2)+   * push it in this program ending memory
    RTS 
Register_111
    MOVE.B  #'7',   (A2)+   * push it in this program ending memory
    RTS 
*-----------------------------------------------------------------------------------------------------------------------
* EA END
*-----------------------------------------------------------------------------------------------------------------------

_LSL_ASR
*bit 6 and 7 determines memory or register
    JSR PREPARE_DATA_REG
     CMP.W #7, D2
    BEQ CHECKD3
    CMP.W #3, D2
    BEQ CHECKD3
    
    CMP.B #$1, D4
    BEQ LSX
    CMP.B #$0, D4
    BEQ ASX
    CMP.B #$5, D4
    BEQ LSX
    CMP.B #$4, D4
    BEQ ASX
    BRA INVALID_OPCODE
CHECKD3
    CMP.B #0, D3
    BEQ ASX
    CMP.B #1, D3
    BEQ LSX
    BRA INVALID_OPCODE  
LSX
    MOVE.B #'L', (A2)+
    MOVE.B #'S', (A2)+
    CMP.W #4, D2
    BGE LEFT_SHIFT
RIGHT_SHIFT
    MOVE.B #'R', (A2)+
    BRA DETERMINE_SHIFT_TYPE    
LEFT_SHIFT
    MOVE.B #'L', (A2)+
DETERMINE_SHIFT_TYPE
    CMP.B #3, D2
    BEQ SHIFT_MEM
    CMP.B #7, D2
    BEQ SHIFT_MEM
    
SHIFT_REG
    LEA SHIFT_TYPE, A0
    LSL.W #8, D1
    LSR.W #8, D1
    LSR.W #6, D1    
    CMP.B   #0, D1
    BEQ     PRINT_BYTE
    CMP.B   #1, D1
    BEQ     PRINT_WORD
    CMP.B   #2, D1
    BEQ     PRINT_LONGWORD
    BRA     INVALID_OPCODE
SHIFT_TYPE
    CMP.W #$5, D4
    BEQ    REG_SHIFT
    CMP.W #$1, D4
    BEQ    NUM_SHIFT
    BRA INVALID_OPCODE
REG_SHIFT
    JSR PRINT_TAB
    MOVE.B #'D', (A2)+
    ADD.W #$30, D3
    MOVE.B D3, (A2)+
    BRA SHIFT_DEST
NUM_SHIFT
    JSR PRINT_TAB
    MOVE.B #'#', (A2)+
    MOVE.B #'$', (A2)+
    CMP.W #0, D3
    BEQ EIGHT
    ADD.W #$30, D3
    MOVE.B D3, (A2)+    
    BRA SHIFT_DEST
EIGHT 
    MOVE.B #'8', (A2)+
    BRA SHIFT_DEST
SHIFT_DEST
    JSR PRINT_TAB
    MOVE.B #'D', (A2)+
    ADD.W #$30, D5
    MOVE.B D5, (A2)+
    RTS
SHIFT_MEM
    MOVE.B #'.', (A2)+
    MOVE.B #'W', (A2)+
    JSR PRINT_TAB
    CMP.W #$2, D4
    BLT INVALID_OPCODE
    JSR EA1
    RTS
ASX
    MOVE.B #'A', (A2)+
    MOVE.B #'S', (A2)+
    CMP.W #4, D2
    BGE LEFT_ROTATE
RIGHT_ROTATE
    MOVE.B #'R', (A2)+
    BRA DETERMINE_ROTATE_TYPE    
LEFT_ROTATE
    MOVE.B #'L', (A2)+
DETERMINE_ROTATE_TYPE
    CMP.B #3, D2
    BEQ ROTATE_MEM
     CMP.B #7, D2
    BEQ ROTATE_MEM
    
ROTATE_REG
    LEA ROTATE_TYPE, A0
    LSL.W #8, D1
    LSR.W #8, D1
    LSR.W #6, D1    
    CMP.B   #0, D1
    BEQ     PRINT_BYTE
    CMP.B   #1, D1
    BEQ     PRINT_WORD
    CMP.B   #2, D1
    BEQ     PRINT_LONGWORD
    BRA     INVALID_OPCODE
ROTATE_TYPE
    CMP.W #$4, D4
    BEQ    REG_ROTATE
    CMP.W #$0, D4
    BEQ    NUM_ROTATE
    BRA INVALID_OPCODE
REG_ROTATE
    JSR PRINT_TAB
    MOVE.B #'D', (A2)+
    ADD.W #$30, D3
    MOVE.B D3, (A2)+
    BRA ROTATE_DEST
NUM_ROTATE
    JSR PRINT_TAB
    MOVE.B #'#', (A2)+
    MOVE.B #'$', (A2)+
    CMP.W #0, D3
    BEQ EIGHT_R
    ADD.W #$30, D3
    MOVE.B D3, (A2)+    
    BRA ROTATE_DEST
EIGHT_R 
    MOVE.B #'8', (A2)+
    BRA ROTATE_DEST
ROTATE_DEST
    JSR PRINT_TAB
    MOVE.B #'D', (A2)+
    ADD.W #$30, D5
    MOVE.B D5, (A2)+
    RTS
ROTATE_MEM
    MOVE.B #'.', (A2)+
    MOVE.B #'W', (A2)+
    JSR PRINT_TAB 
    CMP.W #$2, D4
    BLT INVALID_OPCODE
    JSR EA1
    RTS
*------------------------------------------------
* start to print final result
*------------------------------------------------
OUTPUT_RESULT
*_______PRINT CURRENT ADDRESS______________________________ 
Print_Cur_Addr
    MOVE.L  A5, D2 * move staring addr to d2
    MOVE.B  #0, D5  * counter to read all hex
    MOVE.B  #8, D6  * total number of address is 8 bits just to set up to compare with counter    
Convert_Hex_to_Ascii
    CMP.B   D5, D6  * compare the couter
    BNE Smaller *   Set counter to read 4
    JSR Bigger
    TRAP #15    * extra space   
    RTS  
        
Bigger
    MOVE.B  #6, D0  
    MOVE.B  #32,    D1  
    RTS 
Smaller
    MOVE.B  #0, D3  * set counter to 0  
    MOVE.B  #4, D4  * set counter to 4  
Read_Each_Char              *   Read Each character 
    CMP.B   D3, D4  * compare the counter 
    BEQ Save_Char   * 4 then save char  
    LSL.L   #1, D2   * D2 has the address and do LSL to full register to    
    BCC Append_Zero * while change to 0, does carry clear   
    ADDI.B  #1, D1  
    BRA Next_Bit  

Append_Zero 
    ADDI.B  #0, D1  * append zero because it is 0   
Next_Bit
    ADDI.B  #1, D3  * increase the counter because we read  
    LSL.L   #1, D1  *  In full register value D1 make a shift 1 (0) 
    BRA Read_Each_Char  
Save_Char
    LSR.L   #1, D1  * in the full register value it has single digit of the address 
    CMP.B   #$A,    D1  
    BLT   Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$37,   D1  * it is letter  
    ADDI.B  #1, D5      * increase counter (it is the counter for full memory address counter which should be 8 eventually) 
    MOVE.B  #6, D0      * trap task display single char    
    TRAP    #15 
    CLR.L   D1          * clear d1  
    BRA Convert_Hex_to_Ascii

Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$30,   D1  * it is number  so add 30   
    ADDI.B  #1, D5      * increase counter (it is the counter for full memory address counter which should be 8)    
    MOVE.B  #6, D0      *  trap task display single char    
    TRAP    #15 
    CLR.L   D1  * clear d1  
    BRA Convert_Hex_to_Ascii 

ConvertInput        
       MOVE.B  (A1)+,  D2   
       JSR    ConvertASCII
       ADD.L    D2, D3  * copy D2 to D3 
       *ADDA.L   D3, A4      
       CMPI.B   #$0,    (A1)    
       BEQ GoBack
       LSL.L    #4, D3  * Make room for next byte  
        
       BRA  ConvertInput
GoBack  
        *MOVEA.L D3, A4  
        RTS    
ConvertASCII
        CMPI.B  #$30,   D2     * Any input that are less than 30 is error    
        BLT Invalid
        CMPI.B  #$67,   D2    * Any input that are more or equal to 67 (g) is error 
        BGE Invalid  
        * 30~39 Number
        * 41~46 Cap Letter Till F
        * 61~66 Till f
        CMPI.B   #$39,   D2 * 40 is immeidate data use CMPI   
        BLE IsNumber * If less than 40 then execute  
        *________________________________________________
        CMPI.B  #$40,   D2  *   if it is between 3A (:) and 40 (@) throw Error   
        BLE Invalid
        *_______________________________________________
        CMPI.B  #$41,   D2  * if not compare with 41 (A)    
        BGE IsLetter    *Bigger than or Equal to 41 then execute    
IsNumber
        SUB.B   #$30,   D2        
        RTS 
IsLetter
        * figure out either small leter or capital letter   
        CMPI.B  #$46,   D2  * Compare with small letter F            
        BLE CapitalLetter   * if less or equal to 46 than small letter     
        BRA SmallLetter     * else go to capital letter 
CapitalLetter   
        SUB.B   #$37,   D2   * 46 - 37 = F
        RTS 
SmallLetter  
        CMPI.B  #$60,   D2  * if less than or equal to 60 (') throw Error   
        BLE Invalid
        SUB.B   #$57,   D2    
        RTS
    
*____________________PRINT_DATA_REG____________FIXED_________________________       
PRINT_DATA_REG
    ADD.B  #1, MoveInstructionCounter      
    CMP.B   #7, D5           * check n > 7 
    BGT     INVALID_OPCODE 
    CMP.B   #2, MoveInstructionCounter  
    BEQ PRINT_REAL_DATA_REG
    CMP.B   #0, D5  
    BEQ MovePrintNumFixer_DATA_REG   
    BRA   PRINT_REAL_DATA_REG
    
PRINT_REAL_DATA_REG 
    MOVE.B  #'D',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    CLR.L   D5 
    CLR.L   D7   
    RTS
    
MovePrintNumFixer_DATA_REG  
    CLR.L   D5    
    MOVE.W  D1, D7  
    ANDI.W  #$0007, D7  
    MOVE.W  D7, D5
    CLR.L   D7  
    BRA PRINT_REAL_DATA_REG

*____________________PRINT_ADDRESS_REG_________FIXED________________________        
PRINT_ADDRESS_REG
    ADD.B  #1, MoveInstructionCounter
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    CMP.B   #2, MoveInstructionCounter  
    BEQ PRINT_REAL_ADDRESS_REG
    CMP.B   #0, D5  
    BEQ MovePrintNumFixer_ADDRESS_REG   
    BRA   PRINT_REAL_ADDRESS_REG
    
PRINT_REAL_ADDRESS_REG      
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    CLR.L   D5
    RTS
MovePrintNumFixer_ADDRESS_REG         
    CLR.L   D5    
    MOVE.W  D1, D7  
    ANDI.W  #$0007, D7  
    MOVE.W  D7, D5
    CLR.L   D7
    BRA PRINT_REAL_ADDRESS_REG 

*______________________PAREN________FIXED_____________________________________
PRINT_PAREN_ADDRESS_REG
    ADD.B  #1, MoveInstructionCounter
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    CMP.B   #2, MoveInstructionCounter  
    BEQ PRINT_REAL_PAREN_ADDRESS_REG
    CMP.B   #0, D5  
    BEQ MovePrintNumFixer_PAREN   
    BRA   PRINT_REAL_PAREN_ADDRESS_REG
    
PRINT_REAL_PAREN_ADDRESS_REG    
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    CLR.L   D5
    RTS

MovePrintNumFixer_PAREN      
    CLR.L   D5    
    MOVE.W  D1, D7  
    ANDI.W  #$0007, D7  
    MOVE.W  D7, D5
    CLR.L   D7
    BRA PRINT_REAL_PAREN_ADDRESS_REG

*_________________________INCRE_______FIXED___________________________________    
PRINT_INCRE_ADDRESS_REG
    ADD.B  #1, MoveInstructionCounter
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    CMP.B   #2, MoveInstructionCounter  
    BEQ PRINT_REAL_INCRE_ADDRESS_REG
    CMP.B   #0, D5  
    BEQ MovePrintNumFixer_INCRE   
    BRA   PRINT_REAL_INCRE_ADDRESS_REG
    
PRINT_REAL_INCRE_ADDRESS_REG        
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    MOVE.B  #'+',   (A2)+
    CLR.L   D5  
    RTS
    
MovePrintNumFixer_INCRE     
    CLR.L   D5    
    MOVE.W  D1, D7  
    ANDI.W  #$0007, D7  
    MOVE.W  D7, D5
    CLR.L   D7
    BRA PRINT_REAL_INCRE_ADDRESS_REG     
*___________________________DECRE____FIXED__________________________________    
PRINT_DECRE_ADDRESS_REG
    ADD.B  #1, MoveInstructionCounter
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    *_________ added code to fix___________
    * Free register is D7, going to use D7  
    CMP.B   #2, MoveInstructionCounter  
    BEQ PRINT_REAL_DECRE_ADDRESS_REG 
    CMP.B   #0, D5  
    BEQ MovePrintNumFixer_DECRE   
    BRA   PRINT_REAL_DECRE_ADDRESS_REG   
    
PRINT_REAL_DECRE_ADDRESS_REG    
    *_________end of added code__________
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,     (A2)+
    MOVE.B  #')',   (A2)+
    *MOVE.B  D5,   (A2)+
    CLR.L   D5  
    RTS
*__________added code to fix_________________    
MovePrintNumFixer_DECRE    
    CLR.L   D5    
    MOVE.W  D1, D7  
    ANDI.W  #$0007, D7  
    MOVE.W  D7, D5
    CLR.L   D7
    BRA PRINT_REAL_DECRE_ADDRESS_REG 
*___________End of added code to fix_________

*___________________________DECRE____FIXED__________________________________ 
PRINT_WORD
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'W',   (A2)+
    JMP     (A0)  

PRINT_LONGWORD
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'L',   (A2)+
    JMP     (A0) 

PRINT_BYTE
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'B',   (A2)+
    JMP     (A0) 
    
PRINT_TAB
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    RTS

PREPARE_DATA_REG
    LSL   #8, D1 
    ADDA #1, A5
    MOVE.B (A5)+, D1            * full opcode word in D1
PREPARE_DATA    
    MOVE.W  D1, D2              * copy D1 to D2, for dest mode
    MOVE.W  D1, D3              * copy D1 to D3, for dest register
    MOVE.W  D1, D4              * copy D1 to D2, for src mode
    MOVE.W  D1, D5              * copy D1 to D5, for src register
  
    LSL.W   #7,  D2   
    LSR.W   #8,  D2                     
    LSR.W   #5,  D2             * now D2 in binary: 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest mode

    LSL.W   #4,  D3              
    LSR.W   #8,  D3                     
    LSR.W   #5,  D3             * now D3 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest register
    
    LSL.W   #8,  D4 
    LSL.W   #2,  D4             
    LSR.W   #8,  D4                     
    LSR.W   #5,  D4             * now D4 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src mode
    
    LSL.W   #8,  D5  
    LSL.W   #5,  D5
    LSR.W   #8,  D5               
    LSR.W   #5,  D5             * now D5 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src register
    
    RTS

EA1
    CMP.B #0, D4
    BEQ PRINT_DATA_REG1 
    CMP.B #1, D4 
    BEQ PRINT_ADDRESS_REG1
    CMP.B  #2, D4
    BEQ PRINT_PAREN_ADDRESS_REG1
    CMP.B  #3, D4
    BEQ PRINT_INCRE_ADDRESS_REG1
    CMP.W #$4, D4
    BEQ PRINT_DECRE_ADDRESS_REG1
    CMP.W #$7,D4
    BEQ PRINT_ABSOLUTE_IMMEDIATE_DATA1
PRINT_ABSOLUTE_IMMEDIATE_DATA1                    
    CMP.B #4, D5
    BEQ PRINT_IMMEDIATE_DATA1
    CMP.B #0, D5
    BEQ PRINT_ABSOLUTE_ADDRESS1
    CMP.B #1, D5
    BEQ PRINT_ABSOLUTE_ADDRESS1
    BRA INVALID_OPCODE
PRINT_IMMEDIATE_DATA1
    *if size is byte or word
    CMP.B   #2, D0
    BEQ     READLONGWORD1
    *if size is byte or word
    CLR.L D3
    CLR.L D4
    MOVE.B  #0, D4  
    MOVE.B  #'#',   (A2)+   
    MOVE.B  #'$',   (A2)+   
    MOVE.W  (A5)+,  D3  * increase word size address and store it in D3 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #4, D1     
    JSR GetWord_Value 
    RTS

    *if size is long word
READLONGWORD1    
    MOVE.B  #0, D4  
    MOVE.B  #'#',   (A2)+   
    MOVE.B  #'$',   (A2)+   
    MOVE.L  (A5)+,  D3  *   increase long word size address 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #8, D1  
    JSR GetLongword_Value   
    RTS

PRINT_ABSOLUTE_ADDRESS1
    CMP.B #0, D5
    BEQ WORD_ADDR1
    CMP.B #1, D5
    BEQ LONGWORD_ADDR1
    BRA INVALID_OPCODE
LONGWORD_ADDR1
    MOVE.B  #0, D4  
    MOVE.B  #'$',   (A2)+   
    MOVE.L  (A5)+,  D3  *   increase long word size address 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #8, D1  
    JSR GetLongword_Value   
    RTS
WORD_ADDR1
    CLR.L D3
    CLR.L D4
    MOVE.B  #0, D4  
    MOVE.B  #'$',   (A2)+   
    MOVE.W  (A5)+,  D3  * increase word size address and store it in D3 
    CLR.L   D1  * clear d1 to use as a counter  
    MOVE.B  #4, D1     
    JSR GetWord_Value 
    RTS
PRINT_DATA_REG1
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE 
    MOVE.B  #'D',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    RTS
PRINT_ADDRESS_REG1
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    RTS
PRINT_PAREN_ADDRESS_REG1
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    RTS
PRINT_INCRE_ADDRESS_REG1
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    MOVE.B  #'+',   (A2)+
    RTS
PRINT_DECRE_ADDRESS_REG1
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,     (A2)+
    MOVE.B  #')',   (A2)+
    RTS

*_________________________Error Handle___________________________________      
Invalid 
        LEA Mes_Invalid, A1 * print invalid message 
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA  Get_Input_Start_ADR    * go back to obtain starting adr    
        
Invalid_Starting_Ending_Adr
        LEA Mes_Starting_Ending_Adr_Error,  A1  * print invalid message 
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR     * go back to obatin staring adr 
         
Invalid_Adr_Not_Even
        LEA Mes_EvenNumber_Error,   A1   * print invalid message    
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR     * go back to obtain starting adr 
    
*__________________________Keep Decode after 25_________________________________    
ToContinueProgram
        LEA     Extra_Space,    A1
        MOVE.B  #14,            D0
        TRAP    #15
        LEA Mes_Continue_Read,  A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        *_________ get user input___________    
        MOVE.B  #5, D0  * char at d1    
        TRAP    #15 
        CMP.B   #$0D,   D1   * if it is space   
        BEQ ContinueProgram  
        CMP.B   #$51,   D1  * if it is Q    
        BEQ END_Program 
        CMP.B   #$71,   D1  * if it is q    
        BEQ END_Program
        BRA ToContinueProgram   
ContinueProgram 
        MOVE.B  #0, ProgramCounter  * set  counter to 0 
        RTS
END_Program
        LEA     Extra_Space,    A1
        MOVE.B  #14,            D0
        TRAP    #15
        LEA Mes_Run_Again,   A1     
        MOVE.B  #14,    D0  
        TRAP    #15 
        MOVE.B  #5, D0  *Get user input in D1  
        TRAP    #15 
        CMP.B   #$79,   D1 *y
        BEQ     Get_Input_Start_ADR
        CMP.B   #$59,   D1 *Y
        BEQ     Get_Input_Start_ADR
        CMP.B   #$6E,   D1 *n
        BEQ     FINISH
        CMP.B   #$4E,   D1 *N
        BEQ     FINISH
        BRA     END_Program *Else repeat query

REACH_END_ADR
        LEA     Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15
        LEA     Mes_Reached_End,    A1
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA FINISH  
        
FINISH *End program
        LEA     Extra_Space,    A1
        MOVE.B  #14,            D0
        TRAP    #15
        LEA Mes_TerminateProgram,   A1  * just print out message    
        MOVE.B  #14,    D0  
        TRAP    #15 
    
      SIMHALT
        
*-----------------------------------------------------------------------------------------------------------------------
* VARIABLES
*-----------------------------------------------------------------------------------------------------------------------
CR                              EQU     $0D     *   Carriage Return
LF                              EQU     $0A     *   Line Feed
Extra_Space                     DC.B    CR, LF, 0
*Messages
Mes_Welcome                     DC.B    'Welcome to the Disassembler Program', CR, LF
                                DC.B    'Final Project for CSS 422', CR, LF
                                DC.B    '   Authors:', CR, LF
                                DC.B    '       Yang Hu', CR, LF
                                DC.B    '       Matt Johnson', CR, LF
                                DC.B    '       Jun Park', 0
Mes_Start_Adr                   DC.B    'Please enter start address (word): $', 0
Mes_End_Adr                     DC.B    'Please enter end address (word): $', 0
Mes_Invalid                     DC.B    'The address you provided is invalid', CR, LF, 0
Mes_EvenNumber_Error            DC.B    'The address you provided is not an even ending number',  CR, LF, 0
Mes_Starting_Ending_Adr_Error   DC.B    'Your start address is bigger than or equal to the end address', CR, LF, 0
Mes_Continue_Read               DC.B    'Press enter to continue disassembling. Press Q or q to end early.', CR, LF, 0
Mes_Run_Again                   DC.B    'Run disassembler again? (y or n).', CR, LF, 0
Mes_TerminateProgram            DC.B    'Ending the program...Bye', CR, LF, 0
Mes_Reached_End                 DC.B    'The program reached End Address', CR, LF, 0    
*Storage
UserInput                       DS.L    1   
StartLocData                    DS.L    1   *Starting address
EndLocData                      DS.L    1   *Ending address    
ProgramCounter                  DS.L    1   
MoveInstructionCounter          DS.L    1   
ProgramEnd                      DS.L    1   *Variable to store location where this program ends
*-----------------------------------------------------------------------------------------------------------------------
* VARIABLES END
*-----------------------------------------------------------------------------------------------------------------------

                                END     START


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
