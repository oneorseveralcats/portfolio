      ******************************************************************
      * Date: 02/25/24
      * Purpose: Program #2
      * Tectonics: cobc
      ******************************************************************
           IDENTIFICATION DIVISION.
           PROGRAM-ID. PROGRAM2.

      * Imports all the files here.
           ENVIRONMENT DIVISION.
           INPUT-OUTPUT SECTION.
           FILE-CONTROL.
           SELECT IF-CUSTOMERS ASSIGN TO
               './CUSTOMERS.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT IF-INVENTORY ASSIGN TO
               './INVENTORY.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT IF-TRANSACTIONS ASSIGN TO
               './TRANSACTIONS.DAT'
           ORGANIZATION IS LINE SEQUENTIAL.

           SELECT OF-INVOICES ASSIGN TO
               './INVOICES.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT OF-ERRORS ASSIGN TO
               './ERRORS.DAT'
               ORGANIZATION IS LINE SEQUENTIAL.

      * Lays out the internal structure of the files. Essentially just taken
      * from the assignment specification
           DATA DIVISION.
           FILE SECTION.
           FD  IF-CUSTOMERS.
                   01 CUSTOMERS-TABLE.
                       05 CUSTOMER-ID               PIC A(5).
                       05 FILLER                    PIC A(5).
                       05 CUSTOMER-NAME             PIC A(18).
                       05 CUSTOMER-STREET           PIC A(20).
                       05 CUSTOMER-CITY             PIC A(12).
                       05 CUSTOMER-STATE            PIC A(12).
                       05 CUSTOMER-DEBT             PIC 999.99.
           FD  IF-INVENTORY.
                   01 INVENTORY-TABLE.
                       05 INVENTORY-ITEM-ID         PIC A(6).
                       05 FILLER                    PIC A(5).
                       05 INVENTORY-ITEM-NAME       PIC A(22).
                       05 FILLER                    PIC A(2).
                       05 INVENTORY-STOCK-AMOUNT    PIC 99.
                       05 FILLER                    PIC A(5).
                       05 INVENTORY-REORDER-AMOUNT  PIC 99.
                       05 FILLER                    PIC A(5).
                       05 INVENTORY-ITEM-COST       PIC 99.99.
           FD  IF-TRANSACTIONS.
                   01 TRANSACTIONS-TABLE.
                       05 TRANSACTIONS-CUSTOMER-ID  PIC A(5).
                       05 FILLER                    PIC A(5).
                       05 TRANSACTIONS-ITEM-ID      PIC A(6).
                       05 FILLER                    PIC A(5).
                       05 TRANSACTIONS-ORDER-AMOUNT PIC 99.
                       05 FILLER                    PIC A(5).
                       05 TRANSACTIONS-DISCOUNT     PIC A.


           FD  OF-INVOICES.
                   01 INVOICES-TABLE.
                       05 INVOICES-CUSTOMER-NAME    PIC A(18).
                       05 FILLER                    PIC A(5).
                       05 INVOICES-ITEM-NAME        PIC A(22).
                       05 FILLER                    PIC A(5).
                       05 INVOICES-ITEM-COST        PIC $999.99.
                       05 FILLER                    PIC A(5).
                       05 INVOICES-ORDER-AMOUNT     PIC 999.
                       05 FILLER                    PIC A(5).
                       05 INVOICES-ORIGINAL-COST    PIC $999.99.
                       05 FILLER                    PIC A(5).
                       05 INVOICES-DISCOUNT         PIC 9V99.
                       05 FILLER                    PIC A(5).
                       05 INVOICES-FINAL-COST       PIC $999.99.
           FD  OF-ERRORS.
                   01 ERROR-TABLE.
                       05 ERROR-E    PIC A(5) VALUE "ERROR".
                       05 FILLER     PIC A(5).
                       05 ERROR-TYPE PIC A(3).
                       05 FILLER     PIC A(5).
                       05 ERROR-ID   PIC A(6).

      * Lays out the internal structure of the arrays and then other useful variables
           WORKING-STORAGE SECTION.
               01 CUSTOMERS.
                   05 WS-CUSTOMER-ID    PIC A(5)   OCCURS 10 TIMES.
                   05 FILLER            PIC A(5)   OCCURS 10 TIMES.
                   05 WS-CUSTOMER-NAME  PIC A(18)  OCCURS 10 TIMES.
                   05 WS-STREET         PIC A(20)  OCCURS 10 TIMES.
                   05 WS-CITY           PIC A(12)  OCCURS 10 TIMES.
                   05 WS-STATE          PIC A(12)  OCCURS 10 TIMES.
                   05 WS-DEBTS          PIC 999V99 OCCURS 10 TIMES.
               01 INVENTORY.
                   05 WS-ITEM-ID        PIC A(6)   OCCURS 24 TIMES.
                   05 FILLER            PIC A(5)   OCCURS 24 TIMES.
                   05 WS-ITEM-NAME      PIC A(22)  OCCURS 24 TIMES.
                   05 FILLER            PIC A(2)   OCCURS 24 TIMES.
                   05 WS-STOCK-AMOUNT   PIC 99     OCCURS 24 TIMES.
                   05 FILLER            PIC A(5)   OCCURS 24 TIMES.
                   05 WS-REORDER-AMOUNT PIC 99     OCCURS 24 TIMES.
                   05 FILLER            PIC A(5)   OCCURS 24 TIMES.
                   05 WS-ITEM-COST      PIC 99V99  OCCURS 24 TIMES.

      * CUSTOMERS-LENGTH - used to iterate through customer table.
      * eof-flag         - set if eof when reading in files
      * err-flag         - set if a transaction is invalid
      * customer-index   - stores the index of customer id if exists, if
      *                    not, then will be 0. For checking the validity
      *                    of transactions.
      * inventory-index  - same but for inventory id.
               77 CUSTOMERS-LENGTH PIC 99      VALUE 10.
               77 INVENTORY-LENGTH PIC 99      VALUE 24.
               77 I                PIC 99      VALUE 1.
               77 EOF-FLAG         PIC A       VALUE 'N'.
               77 ERR-FLAG         PIC A       VALUE 'N'.
               77 CUSTOMER-INDEX   PIC 99      VALUE 0.
               77 INVENTORY-INDEX  PIC 99      VALUE 0.
               77 TEMP             PIC 999V99.




      * I wanted to make my main paragraph relatively sparse and to call a lot
      * of relatively small functions/"paragraphs".
           PROCEDURE DIVISION.

           MAIN-PROCEDURE.
               PERFORM OPEN-FILES.

               PERFORM POPULATE-CUSTOMER-TABLE.
               PERFORM POPULATE-INVENTORY-TABLE.

               PERFORM PROCESS-TRANSACTIONS.

               PERFORM PRINT-CUSTOMERS.
               PERFORM PRINT-INVENTORY.

               PERFORM CLOSE-FILES.
               STOP RUN.

      * Just opens all the files, called at the beginning of main.
           OPEN-FILES.
               OPEN INPUT  IF-CUSTOMERS
                           IF-INVENTORY
                           IF-TRANSACTIONS
                    OUTPUT OF-INVOICES
                           OF-ERRORS.

      * Fills the customer table that's in working memory.
           POPULATE-CUSTOMER-TABLE.
               MOVE 1 TO I.
               MOVE 'N' TO EOF-FLAG.
               PERFORM UNTIL (EOF-FLAG = 'Y')
                   READ IF-CUSTOMERS
                       AT END MOVE 'Y' TO EOF-FLAG
                   END-READ

                   IF (EOF-FLAG = 'N') THEN
                       MOVE CUSTOMER-ID
                           TO WS-CUSTOMER-ID(I)
                       MOVE CUSTOMER-NAME
                           TO WS-CUSTOMER-NAME(I)
                       MOVE CUSTOMER-STREET
                           TO WS-STREET(I)
                       MOVE CUSTOMER-CITY
                           TO WS-CITY(I)
                       MOVE CUSTOMER-STATE
                           TO WS-STATE(I)
                       MOVE CUSTOMER-DEBT
                           TO WS-DEBTS(I)

                       ADD I TO 1 GIVING I
                   END-IF
               END-PERFORM.

      * Fills the inventory table that's in working memory.
           POPULATE-INVENTORY-TABLE.
               MOVE 1 TO I.
               MOVE 'N' TO EOF-FLAG.
               PERFORM UNTIL EOF-FLAG = 'Y'
                   READ IF-INVENTORY
                       AT END MOVE 'Y' TO EOF-FLAG
                   END-READ

                   IF (EOF-FLAG = 'N') THEN
                       MOVE INVENTORY-ITEM-ID
                           TO WS-ITEM-ID(I)
                       MOVE INVENTORY-ITEM-NAME
                           TO WS-ITEM-NAME(I)
                       MOVE INVENTORY-STOCK-AMOUNT
                           TO WS-STOCK-AMOUNT(I)
                       MOVE INVENTORY-REORDER-AMOUNT
                           TO WS-REORDER-AMOUNT(I)
                       MOVE INVENTORY-ITEM-COST
                           TO WS-ITEM-COST(I)

                       ADD I TO 1 GIVING I
                   END-IF
               END-PERFORM.

      * Begins working through all the transactions one by one, catching
      * transactions that have errors and logging them, then processing
      * valid transactions.
           PROCESS-TRANSACTIONS.
               MOVE 1 TO I.
               MOVE 'N' TO EOF-FLAG.
               PERFORM UNTIL EOF-FLAG = 'Y'
                   READ IF-TRANSACTIONS
                       AT END MOVE 'Y' TO EOF-FLAG
                   END-READ

                   MOVE 'N' TO ERR-FLAG
                   PERFORM CHECK-TRANSACTION-FOR-ERRORS

                   IF ERR-FLAG = 'N' THEN
                       PERFORM GENERATE-INVOICE
                       PERFORM UPDATE-CUSTOMER-DEBT
                       PERFORM UPDATE-INVENTORY-STOCK
                       PERFORM CHECK-INVENTORY-STOCK-AMOUNT
                   END-IF


               END-PERFORM.

      * Runs functions that check for either customer-id or inventory-id
      * based errors. In the case that it finds either, it will log it to
      * errors.dat.
            CHECK-TRANSACTION-FOR-ERRORS.
               PERFORM CHECK-CUSTOMER-ID.
               IF CUSTOMER-INDEX = 0 THEN
                   PERFORM WRITE-CUSTOMER-ERROR
                   MOVE 'Y' TO ERR-FLAG
               END-IF.

               PERFORM CHECK-INVENTORY-ID
               IF INVENTORY-INDEX = 0 THEN
                   PERFORM WRITE-INVENTORY-ERROR
                   MOVE 'Y' TO ERR-FLAG
               END-IF.

      * Function that traverses the WS-CUSTOMER-ID array of the CUSTOMERS-TABLE
      * to make sure that the TRANSACTIONS-CUSTOMER-ID matches an ID in the
      * CUSTOMERS-TABLE.
           CHECK-CUSTOMER-ID.
               MOVE 0 TO CUSTOMER-INDEX
               PERFORM VARYING I FROM 1 BY 1
               UNTIL (I > CUSTOMERS-LENGTH) OR (NOT CUSTOMER-INDEX = 0)
                   IF WS-CUSTOMER-ID(I) EQUALS TRANSACTIONS-CUSTOMER-ID THEN
                       MOVE I TO CUSTOMER-INDEX
               END-PERFORM.

      * Does the same as the CHECK-CUSTOMER-ID function but for the
      * INVENTORY-TABLE and for the ITEM-ID.
           CHECK-INVENTORY-ID.
               MOVE 0 TO INVENTORY-INDEX
               PERFORM VARYING I FROM 1 BY 1
               UNTIL (I > INVENTORY-LENGTH) OR (NOT INVENTORY-INDEX = 0)
                   IF WS-ITEM-ID(I) EQUALS TRANSACTIONS-ITEM-ID THEN
                       MOVE I TO INVENTORY-INDEX
               END-PERFORM.

      * If there's a customer-id error, this function writes the specifics
      * to errors.dat
           WRITE-CUSTOMER-ERROR.
               MOVE "ERROR" TO ERROR-E.
               MOVE "CUS"   TO ERROR-TYPE.
               MOVE TRANSACTIONS-CUSTOMER-ID  TO ERROR-ID.
               WRITE ERROR-TABLE.

      * If there's a inventory-id error, this function writes the specifics
      * to errors.dat.
           WRITE-INVENTORY-ERROR.
               MOVE "ERROR" TO ERROR-E.
               MOVE "INV"   TO ERROR-TYPE.
               MOVE TRANSACTIONS-CUSTOMER-ID TO ERROR-ID.
               WRITE ERROR-TABLE.

      * Fills in all the fields from the invoice to be written to invoices.dat.
           GENERATE-INVOICE.
               MOVE WS-CUSTOMER-NAME(CUSTOMER-INDEX)
                   TO INVOICES-CUSTOMER-NAME.
               MOVE WS-ITEM-NAME(INVENTORY-INDEX)
                   TO INVOICES-ITEM-NAME.
               MOVE WS-ITEM-COST(INVENTORY-INDEX)
                   TO INVOICES-ITEM-COST.
               MOVE TRANSACTIONS-ORDER-AMOUNT
                   TO INVOICES-ORDER-AMOUNT.

      * NUMVAL-C converts a number with a currency sign into numeric so
      * that you can still do math with it.
               MULTIPLY FUNCTION NUMVAL-C(INVOICES-ITEM-COST)
               BY INVOICES-ORDER-AMOUNT
                   GIVING INVOICES-ORIGINAL-COST.

               PERFORM CALCULATE-DISCOUNT.

               SUBTRACT FUNCTION NUMVAL-C(INVOICES-ORIGINAL-COST)
               FROM INVOICES-DISCOUNT
                   GIVING INVOICES-FINAL-COST.

               WRITE INVOICES-TABLE.


      * computes the discount based on it's letter and also it's other
      * criteria.
           CALCULATE-DISCOUNT.
               MOVE INVOICES-ITEM-COST TO TEMP.
               EVALUATE TRANSACTIONS-DISCOUNT
                   WHEN "A"
                       MULTIPLY TEMP BY 0.10
                           GIVING INVOICES-DISCOUNT
                   WHEN "B"
                       MULTIPLY TEMP BY 0.20
                           GIVING INVOICES-DISCOUNT
                   WHEN "C"
                       MULTIPLY TEMP BY 0.25
                           GIVING INVOICES-DISCOUNT
      * in the assignment it said "buy 3 get one free", but was described
      * as if it was more like "buy 2 get 1 free", so I went with buy 3.
                   WHEN "D"
                       IF INVOICES-ORDER-AMOUNT > 3 THEN
                           MULTIPLY TEMP BY 1.00
                               GIVING INVOICES-DISCOUNT
                       END-IF
                   WHEN "E"
                       IF INVOICES-ORDER-AMOUNT > 1 THEN
                          MULTIPLY TEMP BY 1.00
                               GIVING INVOICES-DISCOUNT
                       END-IF
                   WHEN "Z"
                       MOVE 0 TO INVOICES-DISCOUNT
               END-EVALUATE.

      * just updates the customer debt variable stored in memory.
           UPDATE-CUSTOMER-DEBT.
               ADD WS-DEBTS(CUSTOMER-INDEX)
               TO FUNCTION NUMVAL-C (INVOICES-FINAL-COST)
                   GIVING WS-DEBTS(CUSTOMER-INDEX).

      * decreases the inventory stock based everytime the program processes an
      * a transaction.
           UPDATE-INVENTORY-STOCK.
               SUBTRACT WS-STOCK-AMOUNT(INVENTORY-INDEX)
               FROM INVOICES-ORDER-AMOUNT
                   GIVING WS-STOCK-AMOUNT(INVENTORY-INDEX).

      * if the amount had is less than the amount to restock, send a warning
      * about low quantity.
           CHECK-INVENTORY-STOCK-AMOUNT.
               IF WS-STOCK-AMOUNT(I) < WS-REORDER-AMOUNT(I) THEN
                   DISPLAY "WARNING: GETTING LOW ON ",
                       WS-ITEM-NAME(I), " (", WS-ITEM-ID(I), ")"
               END-IF.

      * goes through the entire customer array, printing out all values
      * in it in a row/record style.
           PRINT-CUSTOMERS.
               PERFORM VARYING I FROM 1 BY 1
               UNTIL (I > CUSTOMERS-LENGTH)
                   DISPLAY WS-CUSTOMER-ID(I), 5 SPACES,
                           WS-CUSTOMER-NAME(I),
                           WS-STREET(I),
                           WS-CITY(I),
                           WS-STATE(I),
                           WS-DEBTS(I)
               END-PERFORM.

      * goes through the entire inventory array and prints it in record style.
           PRINT-INVENTORY.
               PERFORM VARYING I FROM 1 BY 1
               UNTIL (I > INVENTORY-LENGTH)
                   DISPLAY WS-ITEM-ID(I), 5 SPACES,
                           WS-ITEM-NAME(I), 5 SPACES,
                           WS-STOCK-AMOUNT(I), 5 SPACES,
                           WS-REORDER-AMOUNT(I), 5 SPACES,
                           WS-ITEM-COST(I), 5 SPACES
               END-PERFORM.


      * Just closes all the files, called at the end of main.
           CLOSE-FILES.
               CLOSE IF-CUSTOMERS
                     IF-INVENTORY
                     IF-TRANSACTIONS
                     OF-INVOICES
                     OF-ERRORS.

           END PROGRAM PROGRAM2.






      *************************************************************************
      *                           _                                           *
      *                          | | ___   __ _ ___                           *
      *                          | |/ _ \ / _` / __|                          *
      *                          | | (_) | (_| \__ \                          *
      *                          |_|\___/ \__, |___/                          *
      *                                   |___/                               *
      *************************************************************************

      * errors.dat
      *
      * Error     INV     01088
      * Error     INV     01003
      * Error     INV     01088
      * Error     CUS     01004


      * invoices.dat
      *
      * Ruth_Underwood         Mallets                    $021.99     004     $087.96     219     $085.77
      * Nancy_Wilson           Ac._GuitarStrings_12       $008.95     002     $017.90     000     $017.90
      * Steve_Howe             Guitar_Strap_Type_2        $015.95     002     $031.90     000     $031.90
      * Nancy_Wilson           Ac._Guitar_Strings_6       $010.95     003     $032.85     219     $030.66
      * Todd_Rundgren          Pedal:_Distortion          $089.99     001     $089.99     799     $082.00
      * Roine_Stolt            Ac._Guitar_Pick-up         $059.95     002     $119.90     599     $113.91
      * Andy_Latimer           Pedal:_Wah_Wah             $079.99     001     $079.99     000     $079.99
      * Tal_Wilkenfeld         Bass_Strings_4             $013.95     004     $055.80     395     $051.85
      * Nancy_Wilson           Ac._Guitar_Strings_6       $010.95     002     $021.90     000     $021.90
      * Nancy_Wilson           Guitar_Picks               $000.99     009     $008.91     000     $008.91
      * Steve_Howe             Guitar_Chord_Book          $021.99     001     $021.99     000     $021.99
      * Dweezil_Zappa          Pedal:_Flanger             $099.99     001     $099.99     499     $095.00
      * Andy_Latimer           Sheet_Music_Book           $009.95     006     $059.70     995     $049.75
      * Steve_Howe             Guitar_Picks               $000.99     008     $007.92     000     $007.92
      * Nancy_Wilson           Pedal:_Echo                $075.99     001     $075.99     759     $068.40
      * Dweezil_Zappa          E-Bow                      $069.96     001     $069.96     000     $069.96
      * Roine_Stolt            Guitar_Strap_Type_1        $010.95     002     $021.90     095     $020.95
      * Roine_Stolt            Guitar_Strap_Type_1        $010.95     002     $021.90     095     $020.95


      * STDOUT:
      *
      * WARNING: GETTING LOW ON Mallets                (003863)
      * WARNING: GETTING LOW ON Guitar_Strap_Type_2    (001456)
      * WARNING: GETTING LOW ON Guitar_Strap_Type_2    (001456)
      * 010015 Steve_Howe        123_Topographic_Rd  London      England     061.81
      * 010025 Ruth_Underwood    4385_Inca_Rd        Los_Angeles California  399.92
      * 010035 Steve_Hackett     16_Serpentine_Dr    London      England     134.10
      * 010055 Nancy_Wilson      5763_Butterfly_St   Seattle     Washington  166.72
      * 010085 Andy_Latimer      858_Sasquatch_St    Leeds       England     987.18
      * 010155 Dweezil_Zappa     86_Yerbouti_Blvd    Los_Angeles California  164.96
      * 010195 Roine_Stolt       2332_Retropolis     Stockholm   Sweden      225.76
      * 010235 Tal_Wilkenfeld    52525_Beck_Way      Sydney      Australia   251.85
      * 010445 Todd_Rundgren     662_Utopia_St       Los_Angeles California  239.21
      * 010885 Lainey_Schooltree 91_N_Broadway       New_York    New_York    000.00
      * 0001205 Ac._GuitarStrings_12  5 165 105 08.955
      * 0001215 Ac._Guitar_Strings_6  5 055 065 10.955
      * 0001235 El._Guitar_Strings_6  5 225 105 09.955
      * 0001245 El._Guitar_Strings2_6 5 095 085 12.955
      * 0001255 Bass_Strings_4        5 085 105 13.955
      * 0001305 Tuner                 5 065 055 18.955
      * 0001555 Guitar_Picks          5 345 405 00.995
      * 0013115 Guitar_Cord           5 115 105 13.955
      * 0013455 Guitar_Strap_Type_1   5 045 055 10.955
      * 0014565 Guitar_Strap_Type_2   5 045 055 15.955
      * 0015785 Sheet_Music_Book      5 065 055 09.955
      * 0023815 Pedal:_Distortion     5 055 035 89.995
      * 0024425 Pedal:_Flanger        5 045 035 99.995
      * 0025135 Pedal:_Wah_Wah        5 075 035 79.995
      * 0026375 Pedal:_Bass_Effect    5 045 035 89.995
      * 0026385 Pedal:_Echo           5 045 035 75.995
      * 0027815 Pedal:_Volume         5 045 035 69.995
      * 0028985 Guitar_Stand          5 095 055 15.955
      * 0029135 Ac._Guitar_Pick-up    5 045 035 59.955
      * 0031005 Guitar_Polish         5 125 085 19.955
      * 0031015 Guitar_Chord_Book     5 065 035 21.995
      * 0032015 How_to_Tape           5 045 035 19.955
      * 0035755 E-Bow                 5 045 035 69.965
      * 0038635 Mallets               5 025 035 21.995
      *
      * Process finished with exit code 0





      *************************************************************************
      *                 _           _                                _        *
      *        ___ ___ | |__   ___ | |     _ __ ___ _ __   ___  _ __| |_      *
      *       / __/ _ \| '_ \ / _ \| |    | '__/ _ | '_ \ / _ \| '__| __|     *
      *      | (_| (_) | |_) | (_) | |    | | |  __| |_) | (_) | |  | |_      *
      *       \___\___/|_.__/ \___/|_|    |_|  \___| .__/ \___/|_|   \__|     *
      *                                            |_|                        *
      *************************************************************************


      *  a. I did all of it. This project seemed more difficult to divide up
      *     than the previous so it seemed logistically more complicated, and
      *     also seemed like one of us may lose out on certain aspects of COBOL
      *     if we tried to break it up by sections.
      *
      *     I ended up spending probably about 12 hours on the program.

      *     I made it more difficult for myself by using a text editor that
      *     didn't have syntax highlighting and language server support for
      *     COBOL. I personally prefer to use text-editors and recompile source
      *     code on file saving, but this time my stubbornness probably made
      *     the project harder.
      *
      *     I ran into an output issue that I had no idea what was causing it.
      *     I was reading from a file and my code looked like this:
      *
      *     ```cobol
      *     read IF-CUSTOMERS into CUSTOMERS-TABLE
                ...
      *     end-read.
      *     ```
      *
      *     I spent probably 1.5 hours or so trying to debug it without any
      *     hints before switching to the COBOL IDE and it told me that the
      *     into part of that sentence was causing a double read which may
      *     cause errors. I changed it and it fixed it!
      *
      *     I think it eventually got easier after I got 1/3 to 1/2 of the way
      *     through the program. At that point I was already sort of exposed to
      *     the syntax of COBOL and how to implement loops, conditionals, etc.


      *  c. I like the very expressive end-if/end-perform. I also like how
      *     simple it is to read and write from files. I also like that COBOL
      *     is like nothing I've ever programmed in before. It feels like
      *     modern popular languages are very similar in a way that makes
      *     writing programs in them not feel that meaningfully different, and
      *     COBOL (FORTRAN, COMMON LISP, etc.) isn't that which is kind of fun.

      *  d. I didn't like the way that numerics with $ or Z couldn't be used in
      *     computation without conversion. It felt very clunky.
      *
      *     I also didn't like that it seemed like there was no straight
      *     forward way to get the length of an array. It felt like all the
      *     to handle a partially filled array were pretty clunky so I ended up
      *     just hardcoding the lengths of the array to the amount of records
      *     that customers and inventory had.
      *
      *     I don't really like how verbose the language is and how you have to
      *     define files in like 3 different places.

      *  e. I'd be willing to but not really sure if that oportunity will come
      *     up again. I kind of wish I finished it earlier than I did. With the
      *     CL program I finished it a week and a half early which let me play
      *     with the language a lot more and get better at it. I feel like I've
      *     learned a lot in the time that I've played with COBOL, but probably
      *     not enough to write actually good or elegant COBOL (if that's at
      *     all possible).

      *  f. Yeah, totally. I had fun writing this program and think it'd be
      *     cool to be a modern COBOL programmer. It's so interesting the
      *     lifespan of COBOL.
