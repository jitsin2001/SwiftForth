\ Shell-Metzger in-place descending sort of floating array
\   see, e. g., Press et al, Numerical Recipes, Cambridge (1986)

\ usage:  build array containing N or more fp values  A{
\         N A{ }shellsort

\ Forth Scientific Library Algorithm #15

\ ANS compliant, requiring
\     FLOATING-POINT wordset
\     array defining and referencing words as in fsl_util.*
\     The compilation of the test code is controlled by the VALUE TEST-CODE?
\     and the conditional compilation words in the Programming-Tools wordset.

\ Note:  code relies on consecutive storage of array elements
\     testing code uses FSIN , PRECISION and SET-PRECISION 
\       from FLOATING EXT wordset
\       and % , s>f , set-width and }fprint from fsl_util.*

\ (c) Copyright 1994 Charles G. Montgomery.  Permission is granted by the
\ author to use this software for any purpose provided this copyright
\ notice is preserved.

\ SHELLSORT     v1.3    28 October 1994         cgm     

0 VALUE astart  \ storage for base address used in array access

: }shellsort    ( nsize &array -- )

    0 } TO astart
    DUP
    BEGIN       ( nsize mspacing )
      2/ DUP    
    WHILE       ( n m )
      2DUP - 0
      DO        ( n m )
       0 I DO   ( n m )

\ compare Ith and (I+M)th elements 
              DUP I + DUP               ( n m l l )
              FLOATS astart + F@        
              I FLOATS astart + F@      ( n m l ;F: Al Ai )
              F<                \ reverse this to get ascending sort

\ switch them if necessary
              IF  DROP LEAVE            ( n m )
              THEN                      ( n m l )
              FLOATS astart + DUP F@
              I FLOATS astart + DUP F@  ( n m &Al &Ai ;F: Al Ai )
              SWAP F! F!

              DUP NEGATE                ( n m -m )
            +LOOP
      LOOP
    REPEAT   2DROP
;

TEST-CODE? [IF]     \ test code =============================================

33 FLOAT ARRAY Test{

: fillTest{  ( -- )  33 0 DO  I S>F % 0.7 F/ FSIN Test{ I } F!  LOOP  ;

: test_sort  ( -- )
   PRECISION   3 SET-PRECISION  print-width @ 10 print-width !
   fillTest{
   33  Test{ }fprint CR
   33 Test{ }shellsort
   33  Test{ }fprint
   print-width ! SET-PRECISION
;

[THEN]

\ \\\\\\\\\\\\\\\end of file





