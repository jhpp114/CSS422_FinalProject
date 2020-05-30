*-----------------------------------------------------------
* Title      : 68k   Disassembler    
* Written by :
* Date       : 06/xx/2020    
* Description: Final Project    
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
*_______Basic Print Out Welcome Message__________  
    MOVE.B  #0, ProgramCounter * added to test sub and end program  
    LEA Mes_Welcome,    A1  
    MOVE.B  #13,    D0  
    TRAP    #15 
    
*_______Get User Input____________________________
Get_Input_Start_ADR
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
    CLR.L   D2 
    CLR.L   D3  
    CLR.L   D0  *  clear d0 before use it in disassemble
    CLR.L   D1 
    CLR.L   D4  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7   
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4    
    
    *MOVEA.L A6, A4  * store ending address to use after
    *BRA Finish  
  
    
*_______End of User Input Adr______________________________ 

Disassemble_Loop
        CMP.B   #25,    ProgramCounter  
    BEQ Finish  
    ADD.B   #1, ProgramCounter
*   Clear Loop  
    CLR.L   D2 
    CLR.L   D3  
    CLR.L   D0  *  clear d0 before use it in disassemble
    CLR.L   D1 
    CLR.L   D4  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7   
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4  
*   Clear Loop  
    JSR Print_Cur_Addr
    LEA ProgramEnd, A2  * A2    store   program end 
    JSR Disassemble  
    MOVE.B  #$00,   (A2)+   
    LEA ProgramEnd, A1  
    MOVEQ   #13,    D0  
    TRAP    #15 
    *________Before BRA FINISH is for testin purpose_________
    *BRA Finish  *   Finish for now for testing purpose  
    *________________________________________________________
    BRA Disassemble_Loop    
   
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
        
        ADDA #$2, A5
        BRA Disassemble 
        
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
    
    CMP.B #1,   D2
    BNE MOVE_MOVEA_SIZE
    MOVE.B  #'A',   (A2)+

MOVE_MOVEA_SIZE
    LEA MOVE_MOVEA_SRC, A0
    CMP.B   #3, D1
    BEQ     PRINT_WORD
    CMP.B   #2, D1
    BEQ     PRINT_LONGWORD
    JMP     PRINT_BYTE
    
MOVE_MOVEA_SRC
    JSR PRINT_TAB
    CMP.W #$4,D4
    BLE TO_EA
IS_SEVEN
    CMP.W #$7,D4
    BNE INVALID_OPCODE
TO_EA
    JSR EA
    
    MOVE.B  #',',   (A2)+  
    
MOVE_MOVEA_DEST
    JSR PRINT_TAB
    MOVE.L D2, D4      
    MOVE.L D3, D5
    
    CMP.B #$000, D4
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
   JSR EA
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
    * check second hex to determine if it is movem or others
    * movem is 1100 or 1000 others are 1110, 1110, and 1111~ xxx1   
    ANDI.W  #$0C00, D3  
    CMP.W   #$0C00, D3  *
    BEQ _Movem
    CMP.W   #$0800, D3  
    BEQ _Movem  
    BRA Lea_Jsr_Rts 
    * Then it should be either lea, jsr, rts    
    
*_______________movem instruction____________________________________        
_Movem  
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
    
MemoryToRegister

RegisterToMemory
    MOVE.W  (A6)+,  D4  *   get next value data 
    CLR.L D0  * prepare for iteration Dn ... An or An... Dn       
RegiToMemoryCalculate   
                
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
Movem_LongWord_Size 
    MOVE.B  #'L',   (A2)+   
    RTS    
    
Lea_Jsr_Rts
    CLR.L   D3  
    MOVE.W  D4, D3  * save for shift    
    ROL.W   #$4,    D3  
    MOVE.W  D3, D4  * save the shifted bits 
    * shift it to obtain retgister on the last bits xxxx XXXx   
    ROL.W   #3, D4  
    ANDI.W  #$0007, D4  
    * if it is not 7 then it should be LEA 7 then it should be JSR RTS  
    CMP.W   #$0007, D4  
    BEQ JSR_RTS 
    CMP.W   #$0007, D4  
    BNE LEA 
    
JSR_RTS 

LEA 

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
    MOVE.W  D2, D6    
    ROL.W   #4, D6  

    MOVE.W  D6, D5    
    ROL.W   #4, D6  
    MOVE.W  D6, D5  
    ANDI.W  #$000F, D6  
    CMP.W   #$F,    D6         
    BEQ _BLE
    CMP.W   #$E,    D6  
    BEQ _BGT
    CMP.W   #$4,    D6  
    BEQ _BCC
    BRA INVALID_OPCODE  
 
        
_BCC
    MOVE.B  #'B',   (A2)+   * Store BCC at the end of this program  
    MOVE.B  #'C',   (A2)+   
    MOVE.B  #'C',   (A2)+  
    MOVE.B  #' ',   (A2)+   * little space
    MOVE.B  #' ',   (A2)+   * little space
    BRA BXX_Displacement 
    
_BLE
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'L',   (A2)+   
    MOVE.B  #'E',   (A2)+  
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    BRA  BXX_Displacement   
        
_BGT
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'G',   (A2)+   
    MOVE.B  #'T',   (A2)+  
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+  
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
    * will be implemented
    
Ascii_Convert_BXX
    ROL.W   #4, D5  
    MOVE.L  D5, D4  
    ANDI.L  #$0000000F, D4  *   just compare last 4 bits
    CMPI.B  #$09,   D4      *   check is number or letter      
    BLE  IS_NUM 
    ADDI.B  #$37,   D4
    BRA IS_LET   
IS_NUM  
    ADDI.B  #$30,   D4  
    BRA IS_LET  
IS_LET  
    ADDI.B  #1, D7    
    MOVE.B  D4, (A2)+   
    CMP.B   D3, D7    
    BLT Ascii_Convert_BXX
    RTS 

*___________________END OF B brothers__________________________ 
_OR

*______________________SUB_____________________________________________
_SUB
* clear out before use
    CLR.L   D0  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7  
* clear out before use
    MOVE.W  (A5)+,   D2  * load full opcode BCC, BGT, BLE same so D2 has 006x      
    MOVE.W  D2, D6    *     put it into d6 for safe bit play    
    * shoud not call this maybe bad opmode or some weired register exist.   
        *MOVE.B  #'S',   (A2)+   
    *MOVE.B  #'U',   (A2)+   
    *MOVE.B  #'B',   (A2)+   
    *MOVE.B  #'.',   (A2)+   
    * Basic idea
    * all sub 1001 do and operation with 0000 will just 0000
    * if it is ea - dn then 1001 xxx, xxx cannot be 000 so if you do and operation 000 then its always result as 0  
    * after 1001 xxx, then its opmode, for byte (ea - dn) it is always starting with 0 so do and with 1 so it is 0000 
    * Rest of two digit for opmode     
    *   11 and 00  = 00, 11 01 = 01, 11 10 = 10 use this to distinguish 
    ANDI.W  #$01C0, D6  
    * Check opmode using above logic    
    CMP.W   #$0000, D6
    BEQ _Byte_EA_DN     
    CMP.W   #$0040, D6  
    BEQ _Word_EA_DN 
    CMP.W   #$0080,  D6      
    BEQ _Longword_EA_DN 
    * to check DN - EA, since it is same but 1 infront, just put 01 instead of 00   
    CMP.W   #$0100, D6  
    BEQ _Byte_DN_EA 
    CMP.W   #$0140, D6  
    BEQ _Word_DN_EA 
    CMP.W   #$0180, D6  
    BEQ _Longword_DN_EA 
    *_________Else__________Invalid Data_______________ 
    
_Byte_EA_DN     
    MOVE.B  #'S',   (A2)+  
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    JSR Calculate_EA_Mode          
    * land it on here   
    MOVE.B  #',',     (A2)+   
    MOVE.B  #'D',    (A2)+   *Always D   
    MOVE.W  D2,   D4    
    ANDI.W  #$0E00, D4  * compare with 1110 just to check the register field    
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4    
    *ROL.W   #4, D4  
    *ROL.W   #4, D4  
    MOVE.W  D4, D5  
    ANDI.W  #$0007, D4  * same logic, check the number 000, 001, 010, etc          
    JSR Register_Lists  
    RTS 
   
_Word_EA_DN
    MOVE.B  #'S',   (A2)+   
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    MOVE.B  #'W',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    JSR Calculate_EA_Mode
    *   Apply Same logic with Byte_EA_DN  
    MOVE.B  #',',    (A2)+   
    MOVE.B  #'D',    (A2)+    
    MOVE.W  D2, D4
    ANDI.W  #$0E00, D4  
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4  
    MOVE.W  D4, D5  
    ANDI.W  #$0007, D4  
    JSR Register_Lists  
    RTS 
      

_Longword_EA_DN
    MOVE.B  #'S',   (A2)+   
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    MOVE.B  #'L',   (A2)+    
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    JSR Calculate_EA_Mode   
    *   Apply Same logic with Byte_EA_DN    
    MOVE.B  #',',   (A2)+   
    MOVE.B  #'D',   (A2)+   
    MOVE.W  D2, D4  
    ANDI.W  #$0E00, D4  
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4  
    MOVE.W  D4, D5  
    ANDI.W  #$0007, D4 
    JSR Register_Lists  
    RTS

*   sub.b x, Dx 
_Byte_DN_EA
    MOVE.B  #'S',   (A2)+   
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #'D',   (A2)+  
    * Apply Opposite way compare to EA-DN  
    MOVE.W  D2, D4   
    *MOVE.W  D
    ANDI.W  #$0E00, D4  
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4  
    MOVE.W  D4, D5  
    
    ANDI.W  #$0007, D4 
    MOVE.W  D2, D3  
    ROL.W   #4, D3  
    JSR Register_Lists  
    MOVE.B  #',',    (A2)+      
    JSR Calculate_EA_Mode
    RTS 
       
_Word_DN_EA
    MOVE.B  #'S',   (A2)+   
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    MOVE.B  #'W',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #'D',   (A2)+  
    * Apply Opposite way compare to EA-DN  
    MOVE.W  D2, D4   
    *MOVE.W  D
    ANDI.W  #$0E00, D4  
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4  
    MOVE.W  D4, D5  
    
    ANDI.W  #$0007, D4 
    MOVE.W  D2, D3  
    ROL.W   #4, D3  
    JSR Register_Lists  
    MOVE.B  #',',    (A2)+      
    JSR Calculate_EA_Mode
    RTS  

_Longword_DN_EA
    MOVE.B  #'S',   (A2)+   
    MOVE.B  #'U',   (A2)+   
    MOVE.B  #'B',   (A2)+   
    MOVE.B  #'.',   (A2)+   
    MOVE.B  #'L',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #' ',   (A2)+   
    MOVE.B  #'D',   (A2)+  
    * Apply Opposite way compare to EA-DN  
    MOVE.W  D2, D4   
    *MOVE.W  D
    ANDI.W  #$0E00, D4  
    LSR.W   #4, D4  
    LSR.W   #4, D4  
    LSR.W   #1, D4  
    MOVE.W  D4, D5  
    
    ANDI.W  #$0007, D4 
    MOVE.W  D2, D3  
    ROL.W   #4, D3  
    JSR Register_Lists  
    MOVE.B  #',',    (A2)+      
    JSR Calculate_EA_Mode
    RTS  

*____________________END OF SUB________________________________________

* Basic idea
* 000 to 110 so, need to compare with three bits
* Shift until the the Mode in EA is the last bit    
* Simply check the shifted last 3 bit (mode)
*  000 and 111 -> 000
*  001 and 111 - > 001
*  010 and 111 -> 010 etc etc 
Calculate_EA_Mode   
    MOVE.W  D2, D3  * move data value to d3 for shifting purpose
    ROL.W   #4, D3  * Shift
    ROL.W   #3, D3  
    ROL.W   #3, D3  
    ROL.W   #3, D3    
    MOVE.W  D3, D4    
    ANDI.W  #$0007, D3  * check last 3 bits which is mode   
               
    JSR  EA_Lists  

    RTS * go bacc k to     _Byte_EA_DN 
    *BRA Finish  
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
* Apply same logic as EA_List_000   
EA_List_001
    MOVE.B  #'A',   (A2)+   
    ROL.W   #3, D4  
    MOVE.W  D4, D3  
    ANDI.W  #$0007, D4  
    JSR Register_Lists  
    RTS 
    
EA_List_010
    MOVE.B  #'(',   (A2)+   
    MOVE.B  #'A',   (A2)+   
    ROL.W   #3, D4  
    MOVE.W  D4, D3  
    ANDI.W  #$0007, D4  
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   
    RTS 
    
EA_List_011
    MOVE.B  #'(',   (A2)+   
    MOVE.B  #'A',   (A2)+   
    ROL.W   #3, D4  
    MOVE.W  D4, D3  
    ANDI.W  #$0007, D4  
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   
    MOVE.B  #'+',   (A2)+   
    RTS 
    
EA_List_100
    MOVE.B  #'-',   (A2)+   
    MOVE.B  #'(',   (A2)+   
    MOVE.B  #'A',   (A2)+   
    ROL.W   #3, D4  
    MOVE.W  D4, D3  
    ANDI.W  #$0007, D4  
    JSR Register_Lists  
    MOVE.B  #')',   (A2)+   
    RTS 

*   I do not know How to handle this....
*   Maybe just put invalid data?    
EA_List_101
    BRA Finish * End if for now  

EA_List_110
    BRA Finish  
    

EA_List_111    
    
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
    
    CMP.W   #1, D4
    BEQ   Register_001
    CMP.W   #2, D4  
    BEQ Register_010
    CMP.W   #3, D4  
    BEQ Register_011    
Resgister_000

Register_001    
    MOVE.W  D3, D4  * get the value of memory again  
    ROL.W   #8, D4  
    ROL.W   #5, D4  
    ANDI.W  #$0007, D4    
    CMP.B   #$7,    D4  
    BNE Just_One
    MOVE.B  #0, D4  
    MOVE.B  #'$',   (A2)+   
    *MOVE.W  
Just_One           
    MOVE.B  #'1',   (A2)+      
    RTS 
Register_010
    MOVE.B  #'2',   (A2)+   
    RTS 
Register_011
    MOVE.B  #'3',   (A2)+   
    RTS 
Register_100    

Register_101

Register_110

Register_111
*______________________END OF SUB EA_____________________________________________
_CMP
_AND

*______________________ADD_____________________________________________
_CLEAR_DN   *generalized subroutine for clearing data registers before next use
    CLR.L   D0
    CLR.L   D1  
    CLR.L   D2      
    CLR.L   D3  
    CLR.L   D5  
    CLR.L   D6  
    CLR.L   D7
    RTS

_ADD
    JSR     _CLEAR_DN
    MOVE.B  #'A',   (A2)+  
    MOVE.B  #'D',   (A2)+   
    MOVE.B  #'D',   (A2)+   
    JSR     PREPARE_DATA_REG    *preps D2-D5
                                *d2 is now bits 8-6
                                *d3 is now bits 11-9
                                *d4 is now bits 5-3
                                *d5 is now bits 2-0
    CMP.W   #0, D2
    BEQ     _ADD_BYTE_EA_DN
    CMP.W   #4, D2
    BEQ     _ADD_BYTE_DN_EA
    CMP.W   #1, D2
    BEQ     _ADD_WORD_EA_DN
    CMP.W   #5, D2
    BEQ     _ADD_WORD_DN_EA
    CMP.W   #2, D2
    BEQ     _ADD_LONG_EA_DN
    CMP.W   #6, D2
    BEQ     _ADD_LONG_DN_EA

_ADD_BYTE_EA_DN
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'B',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    JSR     _ADD_EA
    MOVE.B  #',',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _DN

_ADD_BYTE_DN_EA
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'B',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _DN
    MOVE.B  #',',   (A2)+
    JSR     _ADD_EA

_ADD_WORD_EA_DN
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'W',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    JSR     _ADD_EA
    MOVE.B  #',',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _DN

_ADD_WORD_DN_EA
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'W',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #' ',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _DN
    MOVE.B  #',',   (A2)+
    JSR     _ADD_EA

_ADD_LONG_EA_DN
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'L',   (A2)+  
    MOVE.B  #' ',   (A2)+  
    MOVE.B  #' ',   (A2)+
    JSR     _ADD_EA
    MOVE.B  #',',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _DN

_ADD_LONG_DN_EA
    MOVE.B  #'.',   (A2)+
    MOVE.B  #'L',   (A2)+  
    MOVE.B  #' ',   (A2)+  
    MOVE.B  #' ',   (A2)+
    MOVE.B  #'D',   (A2)+
    MOVE.L  D3,     D6
    JSR     _N
    MOVE.B  #',',   (A2)+
    JSR     _ADD_EA

_N  *subroutine for pushing n for dn or an based on d6
    CMP.W   #0, D6
    BEQ     _0
    CMP.W   #1, D6
    BEQ     _1
    CMP.W   #2, D6
    BEQ     _2
    CMP.W   #3, D6
    BEQ     _3
    CMP.W   #4, D6
    BEQ     _4
    CMP.W   #5, D6
    BEQ     _5
    CMP.W   #6, D6
    BEQ     _6
    JSR     _7
    RTS

_0
    MOVE.B  #'0',   (A2)+
    RTS

_1
    MOVE.B  #'1',   (A2)+
    RTS

_2
    MOVE.B  #'2',   (A2)+
    RTS

_3
    MOVE.B  #'3',   (A2)+
    RTS

_4
    MOVE.B  #'4',   (A2)+
    RTS

_5
    MOVE.B  #'5',   (A2)+
    RTS

_6
    MOVE.B  #'6',   (A2)+
    RTS

_7
    MOVE.B  #'7',   (A2)+
    RTS

_ADD_EA *d4 is mode, d5 is register
    CMP.W   #0,     D4
    BEQ     _ADD_EA_DN
    CMP.W   #1,     D4
    BEQ     _ADD_EA_AN
    CMP.W   #2,     D4
    BEQ     _ADD_EA_AN_ACTUAL
    CMP.W   #3,     D4
    BEQ     _ADD_EA_AN_POST_INCREMENT
    CMP.W   #4,     D4
    BEQ     _ADD_EA_AN_PRE_DECREMENT
    CMP.W   #7,     D4
    BEQ     _ADD_EA_DATA
    RTS

_ADD_EA_DN
    MOVE.B  #'D',   (A2)+
    RTS

_ADD_EA_AN
    MOVE.B  #'A',   (A2)+
    MOVE.L  D5,     D6
    JSR     _N
    RTS

_ADD_EA_AN_ACTUAL
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    MOVE.L  D5,     D6
    JSR     _N
    MOVE.B  #')',   (A2)+
    RTS

_ADD_EA_AN_POST_INCREMENT
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    MOVE.L  D5,     D6
    JSR     _N
    MOVE.B  #')',   (A2)+
    MOVE.B  #'+',   (A2)+
    RTS

_ADD_EA_AN_PRE_DECREMENT
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    MOVE.L  D5,     D6
    JSR     _N
    MOVE.B  #')',   (A2)+
    RTS

_ADD_EA_DATA
    CMP.W   #0,     D5
    BEQ     _ADD_EA_W
    CMP.W   #1,     D5
    BEQ     _ADD_EA_L
    CMP.W   #4,     D5
    BEQ     _ADD_EA_IMMEDIATE
    RTS

_ADD_EA_W
    *TODO: data
    RTS

_ADD_EA_L
    *TODO: data
    RTS

_ADD_EA_IMMEDIATE
    MOVE.B  #'#',   (A2)+
    *TODO: data
    RTS
*____________________END OF ADD________________________________________

_LSL_ASR
*bit 6 and 7 determines memory or register
    JSR PREPARE_DATA_REG
    CMP.B #$01, D4
    BEQ LSX
    CMP.B #$00, D4
    BEQ ASX
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
    BRA OUTPUT_RESULT
SHIFT_MEM
    CMP.W #$010, D4
    BLT INVALID_OPCODE
    JSR EA
    *BRA OUTPUT_RESULT
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
    BRA OUTPUT_RESULT
ROTATE_MEM
    CMP.W #$010, D4
    BLT INVALID_OPCODE
    JSR EA
    BRA OUTPUT_RESULT


*------------------------------------------------
* start to print final result
*------------------------------------------------
OUTPUT_RESULT
*   Subroutine
*_________________________________________________
*_______PRINT CURRENT ADDRESS______________________________ 
Print_Cur_Addr
    MOVE.L  A5, D2 * move staring addr to d2
    MOVE.B  #0, D5  * counter to read all hex
    MOVE.B  #8, D6  * total number of address is 8 bits just to set up to compare with counter    
Convert_Hex_to_Ascii
    CMP.B   D5, D6  * compare the couter
    BNE Smaller *   Set counter to read 4
    JSR Bigger
    RTS  
Bigger
    MOVE.B  #6, D0  
    MOVE.B  #32,    D1  
    RTS 
Smaller
    MOVE.B  #0, D3  
    MOVE.B  #4, D4  
Read_Each_Char              *   Read Each character 
    CMP.B   D3, D4  
    BEQ Save_Char   
    LSL.L   #1, D2  
    BCC Append_Zero 
    ADDI.B  #1, D1  
    BRA Next_Bit  

Append_Zero 
    ADDI.B  #0, D1  
Next_Bit
    ADDI.B  #1, D3  
    LSL.L   #1, D1  
    BRA Read_Each_Char  
Save_Char
    LSR.L   #1, D1  
    CMP.B   #$A,    D1  
    BLT   Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$37,   D1  
    *ADDI.B  #$30,   D1 
    ADDI.B  #1, D5  
    MOVE.B  #6, D0  
    TRAP    #15 
    CLR.L   D1  
    BRA Convert_Hex_to_Ascii

Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$30,   D1 
    ADDI.B  #1, D5  
    MOVE.B  #6, D0  
    TRAP    #15 
    CLR.L   D1  
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
        BLT Input_Error_Handler
        CMPI.B  #$67,   D2    * Any input that are more or equal to 67 (g) is error 
        BGE Input_Error_Handler  
        * 30~39 Number
        * 41~46 Cap Letter Till F
        * 61~66 Till f
        CMPI.B   #$39,   D2 * 40 is immeidate data use CMPI   
        BLE IsNumber * If less than 40 then execute  
        *________________________________________________
        CMPI.B  #$40,   D2  *   if it is between 3A (:) and 40 (@) throw Error   
        BLE Input_Error_Handler
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
        BLE Input_Error_Handler
        SUB.B   #$57,   D2    
        RTS
EA
    CMP.B #0, D4
    BEQ PRINT_DATA_REG 
       
    CMP.B #1, D4 
    BEQ PRINT_ADDRESS_REG

    CMP.B  #2, D4
    BEQ PRINT_PAREN_ADDRESS_REG
    
    CMP.B  #3, D4
    BEQ PRINT_INCRE_ADDRESS_REG

    CMP.W #$4, D4
    BEQ PRINT_DECRE_ADDRESS_REG
    
    CMP.W #$7,D4
    BEQ PRINT_ABSOLUTE_IMMEDIATE_DATA

PRINT_ABSOLUTE_IMMEDIATE_DATA                    
    CMP.B #4, D5
    BEQ PRINT_IMMEDIATE_DATA
    
    CMP.B #0, D5
    BEQ PRINT_ABSOLUTE_ADDRESS
    CMP.B #1, D5
    BEQ PRINT_ABSOLUTE_ADDRESS
    
    BRA INVALID_OPCODE


PRINT_IMMEDIATE_DATA 
    *if size is byte or word
    CMP.B   #2, D1
    BEQ     READLONGWORD
    
    *if size is byte or word
    MOVE.W  (A5)+, (A2)+
    RTS
    
    *if size is long word
READLONGWORD    
    MOVE.L  (A5)+, (A2)+
    RTS
    
PRINT_ABSOLUTE_ADDRESS    
    CMP.B #0, D5
    BNE LONGWORD_ADDR
    MOVE.W  (A5)+, (A2)+
    RTS
LONGWORD_ADDR
    MOVE.L  (A5)+, (A2)+
    RTS
    
PRINT_DATA_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE 
    MOVE.B  #'D',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    RTS
    
PRINT_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5   
    MOVE.B  D5,   (A2)+
    RTS

PRINT_PAREN_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    RTS
    
PRINT_INCRE_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,   (A2)+
    MOVE.B  #')',   (A2)+
    MOVE.B  #'+',   (A2)+
    RTS
    
PRINT_DECRE_ADDRESS_REG
    CMP.B   #7, D5           * check n > 7
    BGT     INVALID_OPCODE
    MOVE.B  #'-',   (A2)+
    MOVE.B  #'(',   (A2)+
    MOVE.B  #'A',   (A2)+
    ADD.W   #$30,    D5
    MOVE.B  D5,     (A2)+
    MOVE.B  #')',   (A2)+
    MOVE.B  D5,   (A2)+
    RTS
    
    
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
    LSR.W   #8,  D5             * now D5 is 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is src register
    
    RTS

*_________________________Error Handle___________________________________      
Input_Error_Handler
        BRA Invalid 
        
Invalid 
        LEA Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_Invalid, A1 
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA  Get_Input_Start_ADR    
        
Invalid_Starting_Ending_Adr
        LEA  Extra_Space,   A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_Starting_Ending_Adr_Error,  A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR
         
Invalid_Adr_Not_Even
        LEA Extra_Space,    A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        LEA Mes_EvenNumber_Error,   A1  
        MOVE.B  #14,    D0  
        TRAP    #15 
        BRA Get_Input_Start_ADR 
    

    
Finish  SIMHALT             ; halt simulator
        

* Put variables and constants here
* Basic Print Message   
*____________________________________________________________________
CR  EQU $0D     *   Carriage Return
LF  EQU $0A     *   Line Feed
Extra_Space DC.B    CR, LF, 0 
Mes_Welcome     DC.B    'Welcome to Disassembler Program', CR,  LF
                            DC.B    'Final Project for CSS 422',    CR, LF, 0
Mes_Start_Adr       DC.B    'Please Enter Starting Location: $', 0
Mes_End_Adr     DC.B    'Please Enter Ending Location: $', 0

Mes_Invalid DC.B   'The Address You provided is Invalid', CR,  LF,  0   
            
Mes_EvenNumber_Error    DC.B    'The Address You provided is not even ending number',  CR, LF, 0
Mes_Starting_Ending_Adr_Error   DC.B    'Your Starting Address is bigger or equal than Ending Adrress', CR, LF, 0   

RTS_VALUE               DC.W        'RTS',0     * Requested
JSR_VALUE               DC.W        'JSR',0     * Requested
LEA_VALUE               DC.W        'LEA',0     * Requested
NEG_VALUE               DC.W        'NEG',0     * Requested
CMPI_VALUE              DC.W        'CMPI',0    * Requested
CMP_VALUE               DC.W        'CMP',0     * Requested
SUB_VALUE               DC.W        'SUB',0     * Requested
SUBQ_VALUE              DC.W        'SUBQ',0    * Requested
DIVS_VALUE              DC.W        'DIVS',0    * Requested
BRA_VALUE               DC.W        'BRA',0     * Requested
MULS_VALUE              DC.W        'MULS',0    * Requested
ADD_VALUE               DC.W        'ADD',0     * Requested
ADDA_VALUE              DC.W        'ADDA',0    * Requested
AS_VALUE                DC.W        'AS',0      * Requested ASR, ASL
LS_VALUE                DC.W        'LS',0      * Requested LSR, LSL
RO_VALUE                DC.W        'RO',0      * Requested ROR, ROL
BCLR_VALUE              DC.W        'BCLR',0    * Unfinished
LEFT_DIRECTION          DC.W        'L',0
RIGHT_DIRECTION         DC.W        'R',0
OR_VALUE                DC.W        'OR',0      * Extra
MOVEA_VALUE             DC.W        'MOVEA',0   * Requested
MOVE_VALUE              DC.W        'MOVE',0    * Requested
MOVEQ_VALUE             DC.W        'MOVEQ',0   * Extra
DATA_VALUE              DC.W        'DATA',0
HIGHER_VALUE            DC.W        'HI',0
LOWER_OR_SAME_VALUE     DC.W        'LS',0
CARRY_CLEAR_VALUE       DC.W        'CC',0
NOT_EQUAL_VALUE         DC.W        'NE',0
EQUAL_VALUE             DC.W        'EQ',0
OVERFLOW_CLEAR_VALUE    DC.W        'VC',0 *
OVERFLOW_SET_VALUE      DC.W        'VS',0
PLUS_VALUE              DC.W        'PL',0
MINUS_VALUE             DC.W        'MI',0
GREATER_OR_EQUAL_VALUE  DC.W        'GE',0 *
LESS_THAN_VALUE         DC.W        'LT',0 *
GREATER_THAN_VALUE      DC.W        'GT',0
LESS_OR_EQUAL_VALUE     DC.W        'LE',0
CARRY_SET_VALUE         DC.W        'CS',0 *
SR_VALUE                DC.W        'SR',0
CCR_VALUE               DC.W        'CCR',0
OPENING_BRACKET         DC.W        '(',0
CLOSING_BRACKET         DC.W        ')',0
PLUS_SIGN               DC.W        '+',0
MINUS_SIGN              DC.W        '-',0
DATA_REGISTER           DC.W        'D',0
ADDRESS_REGISTER        DC.W        'A',0
COMMA                   DC.W        ',',0
SPACE                   DC.W        ' ',0
BINARY_SYMBOL           DC.W        '%',0
HEX_SYMBOL              DC.W        '$',0
IMMEDIATE_DATA_SYMBOL   DC.W        '#',0
BYTE_SUFFIX             DC.W        '.B',0
WORD_SUFFIX             DC.W        '.W',0
LONG_SUFFIX             DC.W        '.L',0
ZERO                    DC.W        '0',0
ONE                     DC.W        '1',0
TWO                     DC.W        '2',0
THREE                   DC.W        '3',0
FOUR                    DC.W        '4',0
FIVE                    DC.W        '5',0
SIX                     DC.W        '6',0
SEVEN                   DC.W        '7',0
*EIGHT                   DC.W        '8',0
NINE                    DC.W        '9',0
A                       DC.W        'A',0
B                       DC.W        'B',0
C                       DC.W        'C',0
D                       DC.W        'D',0
E                       DC.W        'E',0
F                       DC.W        'F',0

   
*_______________________________________________________________________________
* Variables to check if it goes to correct area
Move_Print  DC.B    'MOVE', 0   
BCC_Print   DC.B    'BCC',  0   

* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
StartLocData    DS.L    1   * store starting address
EndLocData  DS.L    1   *   Store ending address    
ProgramCounter  DS.L    1   
ProgramEnd DS.L 1   *   variable to store location where this program ends
    END    START        ; last line of source
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
