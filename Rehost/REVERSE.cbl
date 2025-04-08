       IDENTIFICATION DIVISION.
       PROGRAM-ID. REVERSE.

       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.

       01 WS-COUNTERS.
          05 WS-I              PIC 9(02) VALUE 0.
          05 WS-J              PIC 9(02) VALUE 0.
          05 WS-K              PIC 9(02) VALUE 0.
          05 WS-RESP           PIC S9(8)  COMP VALUE +0.
       01 WS-WORK-AREA.
           05 WS-STRING        PIC X(10) VALUE SPACES.
           05 WS-REVERSE-STRING 
                               PIC X(10) VALUE SPACES.

                               COPY REVMAP.

       PROCEDURE DIVISION.
       MAIN-PARAGRAPH.

           exec cics send
               map('REVMENU')
               mapset('REVMAP')
               freekb
               erase
           end-exec
           exec cics receive
               map('REVMENU')
               mapset('REVMAP')
               RESP  (WS-RESP)
           end-exec
           
           IF WS-RESP = DFHRESP(MAPFAIL)
               exec cics send text from (WS-STRING)
                       erase
                       freekb
               end-exec
               exec cics return end-exec
           END-IF

           PERFORM CALCULATE-STRING-LENGTH
           PERFORM REVERSE-STRING

           exec cics send
               map('REVMENU')
               mapset('REVMAP')
               freekb
               erase
           end-exec.
           
           exec cics return TRANSID ('RVRS') end-exec.
              
       CALCULATE-STRING-LENGTH.
           INSPECT WORDINI OF REVMENUI TALLYING WS-I
             FOR CHARACTERS BEFORE INITIAL SPACE.

       REVERSE-STRING.
           MOVE SPACES TO WS-REVERSE-STRING.
           MOVE WORDINI OF REVMENUI TO WS-STRING.
           MOVE WS-I TO WS-J WS-K.

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-K
               MOVE WS-STRING(WS-J:1) TO WS-REVERSE-STRING(WS-I:1)
               SUBTRACT 1 FROM WS-J
           END-PERFORM.
           MOVE WS-REVERSE-STRING TO WORDOUTO OF REVMENUO.

