*** Hello Example ***
         DSK   MY FILE,D2 ; bad ProDOS name
         ORG   $300
COUT     EQU   $FDED      ; Apple II ROM
         DO    0
print    MAC              ; macro definition
         LDY   #$00
:loop    LDA   ]1,Y       ; illegal local label
         BEQ   done
         JSR   COUT
         INY
         BRA   :loop      ; illegal op (missing XC)
done     EOM
         FIN   $00        ; unexpected argument
         print hello      ; not defined in file
         RTS
HELLO    ASC   &"Hello!"&,00 ; dstring
