\ factorial           compute the factorial of a positive integer

\ Forth Scientific Library Algorithm #14

\ Note: this word takes a single precision integer and returns a
\       double precision integer
\
\ This is an ANS Forth program requiring:
\      1. The word 'SD*' is needed for single precision by double precision
\         integer multiply (double precision result).
\         : SD*   ( multiplicand  multiplier_double  -- product_double  )
\                 2 PICK * >R   UM*   R> +
\         ;
\
\      2. The words 'DOUBLE' and 'ARRAY' to create a
\         1-dimensional double precision integer array, for the test code.

\ Note because the factorial function grows rapidly, this function has
\ a range of validity that is dependent upon the number of bits used to
\ represent numbers.  For a 32 bit system, input parameters in the range
\ 0..20 are valid.  The small range of validity makes this function
\ practical to implement in tabular form for some applications.

\     (c) Copyright 1994  Everett F. Carter.     Permission is granted
\     by the author to use this software for any application provided
\     this copyright notice is preserved.


CR .( FACTORIAL         V1.1           18 October 1994   EFC )

: factorial ( n -- d! )
        1. ROT           \ put a double 1 on stack under parameter

        ?DUP IF
                1 SWAP DO I ROT ROT SD* -1 +LOOP
             THEN
;



?TEST-CODE [IF]     \ test code =============================================

10 DOUBLE ARRAY table{

: init-table
      1. table{ 0 } 2!
      1. table{ 1 } 2!
      2. table{ 2 } 2!
      6. table{ 3 } 2!
     24. table{ 4 } 2!
    120. table{ 5 } 2!
    720. table{ 6 } 2!
   5040. table{ 7 } 2!
  40320. table{ 8 } 2!
 362880. table{ 9 } 2!
;

: factorial-test ( -- )

    init-table

    CR
    10 0 DO
           I . I factorial D. table{ I } 2@ D. CR
         LOOP
;

[THEN]
