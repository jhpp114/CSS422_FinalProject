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
    MOVE.L  #$00000000, A1  
    MOVE.L  #$00000000, A2    
    MOVE.L  #$00000000, A3    
    MOVE.L  #$00000000, A4    
    
    *BRA Finish  
    
*_______End of User Input Adr______________________________ 

    JSR Print_Cur_Addr
    LEA ProgramEnd, A2  * A2    store   program end 
    JSR Disassemble

*_______Start of reading machine code______________________

Disassemble                     * while A5 is less than A6
        MOVE.L A5, D0
        CMP.L A6, D0
        BGE OUTPUT_RESULT
        
        MOVE.B (A5), D1        * read a byte from from A5, store to D1. This contains opcode
        
        *valid opcode bits cases: 10-EF
        CMP.B #$10, D1     
        BLT    INVALID_OPCODE   * invalid, need to move on to the next word
        
        CMP.B  #$3F, D1          * 0001 - 0011 -> -> 10 - 3F -> MOVE, MOVEA            * 
        BLE    _MOVE_MOVEA
        
        CMP.B  #$4F, D1          * 0100 -> 40 - 4F -> MOVEM, LEA, JSR, RTS
        BLE _MOVEM_LEA_JSR_RTS
        
        CMP.B #$6F, D1           * 0110 -> 50 - 5F -> BCC (note it should not be 5F)
        BLE _BXX  
        
        CMP.B #$80, D1           * 60 - 7F invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        
        CMP.B #$8F, D1           * 1000 -> 80 - 8F -> OR
        BLE _OR
        
        CMP.B #$9F, D1           * 1001 -> 90 - 9F -> SUB
        BLE _SUB
        
        CMP.B #$B0, D1           * A0 - AF invalid
        BLT    INVALID_OPCODE    * invalid, need to move on to the next word

        CMP.B #$BF, D1           * 1011 -> B0 - BF -> CMP
        BLE _CMP
        
        CMP.B #$CF, D1           * 1100 -> C0- CF -> AND
        BLE _AND
        
        CMP.B #$DF, D1           * 1101 -> D0 - DF -> ADD
        BLE _ADD
        
        CMP.B #$EF, D1           * 1110 -> E0 - EF -> LSL, ASR
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
    LSL   #8, D1 
    ADDA #1, A5
    MOVE.B (A5)+, D1            * full opcode word in D1
    MOVE.W  D1, D2              * copy D1 to D2
    LSL   #7, D2                
    *LSR   #13, D2               * now D2 in binary: 0000 0000 0000 0000 0000 0000 0000 0xxx, xxx is dest mode
    
    
                      
    *CMP.B #$1F                  * size Byte
    *BLE   _MOVE_MOVEA_B
      
    *CMP.B #$2F                  *size Word
    *BLE   _MOVE_MOVEA_W
    
    *CMP.B #$2F                  *size Longword
    *BLE   _MOVE_MOVEA_L
    
    
_MOVEM_LEA_JSR_RTS
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
    *ANDI.W  #$000F, D6  
    *MULU    #8, D6  
    
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
    
_BGT

BXX_Displacement    
    MOVE.W  D2, D6  *   Load full memory 
    MOVE.L  A5, D5  *   Load current starting adr from user
    MOVE.B  #0, D1  *   set up counter 0 to 8   
    MOVE.B  #8, D2  
    ANDI.W  #$00FF, D6  *   00XX
    CMP.W   #$00,   D6  *   if 00 then it should be 8bit displacement   
    BEQ BXX_DISPLACEMENT_WORD      
    CMP.W   #$FF,   D6  *   if  FF then it should be 16 bits displacement   
    BEQ BXX_DISPLACEMENT_LONG   
    BRA BXX_DISPLACEMENT_8Bit   *   rest of them are 8 bit  
  
   
BXX_DISPLACEMENT_8Bit
    MOVE.W  D2, D6  *   Load full memory    
    BRA Finish  *   End for now 

BXX_DISPLACEMENT_WORD

BXX_DISPLACEMENT_LONG   



*___________________END OF B brothers__________________________ 
_OR
_SUB
_CMP
_AND
_ADD
_LSL_ASR
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
    BRA   Next_HEX

Convert_Ascii_to_Hex_DisplayAdr 
    ADDI.B  #$30,   D1  
Next_HEX
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
  
*_______________________________________________________________________________
* Variables to check if it goes to correct area
Move_Print  DC.B    'MOVE', 0   
BCC_Print   DC.B    'BCC',  0   

* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
StartLocData    DS.L    1   * store starting address
EndLocData  DS.L    1   *   Store ending address    
ProgramEnd DS.L 1   *   variable to store location where this program ends
    END    START        ; last line of source









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
