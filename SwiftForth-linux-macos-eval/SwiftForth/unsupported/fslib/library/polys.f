\ polys             evaluation of various special polynomials.
\        Uses recurrance relations to do the evaluation from lower orders

\ Forth Scientific Library Algorithm #21

\ Ch_n   ACM # 10, Evaluates the nth order Chebyschev Polynomial (first kind),
\        Ch_n(x) = cos( n * cos^-1(x) )

\ He_n   ACM # 11, Evaluates the nth order Hermite Polynomial,
\        He_n(x) = (-1)^n exp( x^2 ) d^n exp( - x^2 ) /dX^n

\ La_n   ACM # 12, Evaluates the nth order Laguerre Polynomial,
\        La_n(x) = exp(x) d^n X^n exp( - x ) /dX^n

\ Lag_n   Evaluates the nth order Generalized Laguerre Polynomial,
\        Lag_n(x,a)

\ Le_n   ACM # 13, Evaluates the nth order Legendre Polynomial,
\        La_n(x) = 1/(2^n n!) d^n (X^2 -1)^n /dX^n

\ Be_n   Evaluates the nth order Bessel Polynomial,
\        Be_n(x) = \sum_k=0^n d_k x^k,  d_k = (2 n - k)!/(2^(n-k) k! (n-k)!

\ These algorithms have very similar internal structure that could in principle
\ be factored out, for reasons of computational efficiency this was factorization
\ was not done.

\ This code conforms with ANS requiring:
\      1. The Floating-Point word set
\      2. Uses a local variable mechanism implemented in 'fsl_util.seq'
\      3. The compilation of the test code is controlled by the VALUE ?TEST-CODE
\         and the conditional compilation words in the Programming-Tools wordset

\ Collected Algorithms from ACM, Volume 1 Algorithms 1-220,
\ 1980; Association for Computing Machinery Inc., New York,
\ ISBN 0-89791-017-6

\ The original publication of Laguerre polynomial evaluation had some
\ errors, these are corrected in this code.

\ see also
\ Conte, S.D. and C. deBoor, 1972; Elementary Numerical Analysis,
\ an algorithmic approach, McGraw-Hill, New York, 396 pages

\ The Bessel polynomial is described in,
\ Rabiner, L.R. and B. Gold, 1975; Theory and Application of Digital
\ Signal Processing, Prentice-Hall, Englewood Cliffs, N.J. 762 pages
\ ISBN 0-13-914101-4

\ (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.


CR .( POLYS             V1.1           21 September 1994 EFC )


: Ch_n ( n -- ) ( f: x -- z )        \ nth order 1st kind Chebyschev Polynomial
        \ set up a local fvariable frame
        FDUP  1.0e0 
        FRAME| a b c |

        DUP 0= IF DROP 1.0e0  &b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c b F* 2.0e0 F* a F-
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b

        |FRAME
;

: He_n ( n -- ) ( f: x -- z )          \ nth order Hermite Polynomial
        \ set up a local fvariable frame, c (=x) then b then a
        2.0e0 F* FDUP 1.0e0
        FRAME| a b c |

        DUP 0= IF DROP 1.0e0 &b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c b F*
                                   I 2* S>F a F* F-
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

         b   \ b contains the result

         |FRAME
;

: La_n ( n -- ) ( f: x -- z )          \ nth order Laguerre Polynomial
        \ set up a local fvariable frame, c then b then a
        1.0e0 FOVER F- 1.0e0
        FRAME| a b c |


        DUP 0= IF DROP 1.0e0 &b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   I 2* 1+ S>F c F- b F*
                                   I S>F a F* F-
                                   I 1+ S>F F/
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b
        |FRAME
;

\ nth order generalized Laguerre Polynomial
\ NOTE EXTRA PARAMETER COMPARED TO OTHER POLYNOMIALS,
\      for alpha = 0.0 this polynomial is the same as La_n
: Lag_n ( n -- ) ( f: x alpha -- z )
        \ set up a local fvariable frame, d then c then b then a
        FSWAP 1.0e0 FOVER F-  1.0e0
        FRAME| a b c d |

        d b F+ &b F!

        DUP 0= IF DROP 1.0e0 &b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   I 2* 1+ S>F d F+ c F- b F*
                                   I S>F d F+ a F* F-
                                   I 1+ S>F F/
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b
        |FRAME
;

: Le_n ( n -- ) ( f: x -- z )               \ nth order Legendre Polynomial
        \ set up a local fvariable frame, c then b then a
        FDUP 1.0e0
        FRAME| a b c |

        DUP 0= IF DROP 1.0e0 &b F!
               ELSE
                   DUP 1 > IF

                              1 DO
                                   c b F* FDUP a F-
                                   I S>F I 1+ S>F F/ F* F+
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

        b
        |FRAME
;


: Be_n ( n -- ) ( f: x -- z )          \ nth order Bessel Polynomial
        \ set up a local fvariable frame, c then b then a
        1.0e0 FOVER F+ 1.0e0
        FRAME| a b c |

        DUP 0= IF DROP 1.0e0 &b F!
               ELSE
                   DUP 1 > IF

                              1+ 2 DO
                                   I 2* 1- S>F b F*
                                   c FDUP F* a F* F+
                                   b &a F!
                                   &b F!
                                LOOP

                           ELSE
                                DROP
                           THEN
               THEN

         b
         |FRAME
;


Reset_Search_Order

?TEST-CODE [IF]     \ test code =============================================

\ test code for polynomials

v: poly

& He_n defines poly

: test-polys ( n -- )

     CR

     \ ."           "
     \ DUP 3 DO ."     " I . LOOP CR

     5 0 DO
             I S>F 0.25e0 F*  -0.25e0 F+
             \ FDUP F. ."     "


             DUP 3 DO
                    FDUP I   poly F. ."   "
                 LOOP

             FDROP CR

     LOOP

     DROP
;

: test-gpoly ( n -- ) ( f: alpha -- )

     CR

     5 0 DO
             I S>F 0.25e0 F*  -0.25e0 F+
             \ FDUP F. ."     "
             
             DUP 3 DO
                    FOVER FOVER FSWAP I   poly F. ."   "
                 LOOP

             FDROP CR

     LOOP

     FDROP   DROP
;

\ comparison values generated from Mathematica V2.2
: cheby-table ( -- )
     ."   0.6875   0.53125   -0.953125   -0.0546875   0.980469 -0.435547 " cr
     ."   0.0      1.0        0.0        -1.0         0.0       1.0 " cr
     ."  -0.6875   0.53125    0.953125   -0.0546875  -0.980469 -0.435547 " cr
     ."  -1.0     -0.5        0.5         1.0         0.5      -0.5 " cr
     ."  -0.5625  -0.96875   -0.890625   -0.367187    0.339844  0.876953 " cr
;

: hermite-table ( -- )
      ."   2.875   9.0625   -27.5312   -76.8594   368.805   891.629 " cr
      ."   0.0    12.0        0.0     -120.0        0.0    1680.0 " cr
      ."  -2.875   9.0625    27.5312    -76.8594  -368.805  891.629 " cr
      ."  -5.0     1.0       41.0        31.0     -461.0   -895.0 " cr
      ."  -5.625  -9.9375    30.0937    144.516   -144.352 -2239.75 " cr
;

: laguerre-table ( -- )
     ."   1.84635   2.19808   2.58936    3.02332     3.50327   4.03269 " cr
     ."   1.0       1.0       1.0        1.0         1.0       1.0 "     cr
     ."   0.341146  0.177246  0.037264  -0.0809404 -0.179368 -0.259886 " cr
     ."  -0.145833 -0.330729 -0.445573  -0.504145  -0.518339 -0.498363 " cr
     ."  -0.476562 -0.580566 -0.576685  -0.501364  -0.383086 -0.243679 " cr
;

: legendre-table ( -- )
   ."   0.335937   0.157715  -0.339722   0.0242767   0.279919  -0.152454 " cr
   ."   0.0        0.375      0.0       -0.3125      0.0        0.273437 " cr
   ."  -0.335937   0.157715   0.339722   0.0242767  -0.279919  -0.152454 " cr
   ."  -0.4375    -0.289062   0.0898437  0.323242    0.223145  -0.0736389 " cr
   ."  -0.0703125 -0.350098  -0.416382  -0.280777   -0.0341835  0.197609 " cr
;

: glaguerre-table ( -- )     \ for alpha = 0.75
   ."   4.41667   5.90365   7.61446   9.56526  11.7909   14.3154 " cr
   ."   3.00781   3.57178   4.10754   4.62099   5.11609   5.59573 " cr
   ."   1.83333   1.79687   1.6724    1.48342   1.24821   0.981352 " cr
   ."   0.877604  0.506673  0.103621 -0.291272 -0.651256 -0.959288 " cr
   ."   0.125    -0.367187 -0.779687 -1.07754  -1.2493   -1.29858 " cr
;

: bessel-table ( -- )
   ." 11.609375  81.410156  733.416992  8072.675049 " cr
   ." 15.0      105.0       945.0      10395.0      " cr
   ." 19.140625 134.222656 1209.200195 13309.591064 " cr
   ." 24.125    170.0625   1536.59375  16945.046875 " cr
   ." 30.046875 213.597656 1939.280273 21452.231689 " cr
;

: test-cheby ( -- )
   & Ch_n defines poly
   9 test-polys
   CR ." Comparison values " CR
   cheby-table

;

: test-hermite ( -- )

     & He_n defines poly
     9 test-polys
     CR ." Comparison values " CR
     hermite-table
;

: test-laguerre ( -- )

     & La_n defines poly
     9 test-polys
     CR ." Comparison values " CR
     laguerre-table
;

: test-legendre ( -- )
    & Le_n defines poly
    9 test-polys
    CR ." Comparison values " CR
    legendre-table
;

: test-glaguerre ( -- )

     0.75e0                  \ alpha
     & Lag_n defines poly
     9 test-gpoly
     CR ." Comparison values " CR
     glaguerre-table
;

: test-bessel ( -- )

      & Be_n defines poly
      7 test-polys
      CR ." Comparison values " CR
      bessel-table

;


[THEN]
