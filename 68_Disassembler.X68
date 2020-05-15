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
    BNE Invalid_Adr_Not_Even * Not even then go to invalid        
    
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
    
    BRA Finish  
    
*_______End of User Input Adr______________________________ 
*   Subroutine
*_________________________________________________
ConvertInput        
       MOVE.B  (A1)+,  D2   
       JSR    ConvertASCII
       ADD.L    D2, D3  * copy D2 to D3       
       CMPI.B   #$0,    (A1)    
       BEQ GoBack
       *LSL.B    #4, D2     
       *LSR.B    #4, D2    
       LSL.L    #4, D3  * Make room for next byte   
       *ADD.L    D2, D3 
       BRA  ConvertInput
GoBack
        * trying on checking input length
        *CMP.W   #$0009, D3  
        *BGE  Input_Error_Handler  
        RTS    
       *LSR.B    
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
        *CMPI.B  #$40,   D2  
        *BLE Input_Error_Handler 
        SUB.B   #$37,   D2   * 46 - 37 = F
        RTS 
SmallLetter  
        CMPI.B  #$60,   D2  * if less than or equal to 60 (') throw Error   
        BLE Input_Error_Handler
        SUB.B   #$57,   D2    
        RTS 
        * tomorrow continue (less than 39) then subtract 30
     
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
        *MOVE.B  #9, D0    
        *TRAP    #15
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

*        RTS 
      
   

* Put variables and constants here
* Basic Print Message   
*____________________________________________________________________
CR  EQU $0D     *   Carriage Return
LF  EQU $0A     *   Line Feed
Extra_Space DC.B    CR, LF, 0 
Mes_Welcome     DC.B    'Welcome to Disassembler Program', CR,  LF
                            DC.B    'Final Project for CSS 422',    CR, LF, 0
Mes_Start_Adr       DC.B    'Please Enter Starting Location: ', 0
Mes_End_Adr     DC.B    'Please Enter Ending Location: ', 0

Mes_Invalid DC.B   'The Address You provided is Invalid', CR,  LF
          DC.B 'Terminating Program.',  CR, LF, 0    
Mes_EvenNumber_Error    DC.B    'The Address You provided is not even ending number',  CR, LF, 0
Mes_Starting_Ending_Adr_Error   DC.B    'Your Starting Address is bigger or equal than Ending Adrress', CR, LF, 0   
  

* Define Storage
*_____________________________________________________________________
UserInput   DS.L    1   
StartLocData    DS.L    1   * store starting address
EndLocData  DS.L    1   *   Store ending address    

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
