\ COMPLEX   A definition of a complex number type and associated operations on it.
\           These are the words that might care about the implementation details
\           of the Complex type.  This file specifies the SYNTAX of operations
\           on the complex data type.  The internals of the implementation here
\           are typical but should not be assumed by other programs as they
\           very likely could be rewritten for efficiency on specfic platforms
\           or compilers.

\ For the sake of possible optimizations, the following words are also defined here
\ in spite of the fact that they can be defined without knowledge of the
\ details of implementation:
\ Z+      sum of two complex numbers
\ Z-      difference of two complex numbers
\ Z*      product of two complex numbers
\ ZABS    complex magnitude
\ Z/      complex division


\ The Z/ routine does the complex division (x1,y1)/(x2,y2)
\ The ZABS routine finds Magnitude of the pair(x,y)

\ If the CONSTANT PLAUGER-CODE? is defined to be TRUE then,
\     the routines ZABS and Z/ are designed to preserve as much precision
\     as possible. They are based upon the algorithms described in:
\        Plauger, P.J., 1994; Complex Made Simple, Embedded Systems Programming,
\        July, pp. 85-88
\ otherwise the obvoius straightfoward algorithm is used.


\ This is an ANS Forth program requiring:
\      1. The Floating-Point word set
\      2. The immediate word '%' which takes the next token
\         and converts it to a floating-point literal
\         : %   BL WORD  COUNT  >FLOAT  0= ABORT" NAN"
\               STATE @  IF POSTPONE FLITERAL  THEN  ; IMMEDIATE
\
\      3. The word 'F,' to store an floating point number at (FALIGNED) HERE
\         : F,  ( f: x -- )        HERE 1 FLOATS ALLOT F! ;

\      4. Uses words 'Private:', 'Public:' and 'Reset_Search_Order'
\         to control the visibility of internal code.

\  (c) Copyright 1994 Everett F. Carter.  Permission is granted by the
\  author to use this software for any application provided this
\  copyright notice is preserved.

CR .( COMPLEX           V1.4           21 December 1994   EFC )

Private:

FALSE CONSTANT PLAUGER-CODE?             \ set to TRUE or FALSE as desired
                                         \ before compiling

FVARIABLE t-real
FVARIABLE t-imag
FVARIABLE scale-factor

PLAUGER-CODE? [IF]


% 2.0 FSQRT         FCONSTANT sqrt2.0
sqrt2.0 % 1.4142 F- FCONSTANT little-bits

: zabs-xy ( -- , f: x y -- x y )

        FABS FSWAP FABS        \ first set absolute values ( x y -- y x )

        \ now put smallest on top of the stack
        FOVER FOVER F< IF FSWAP THEN


;

: set-scale-factor ( -- , f: x y -- x y )

           FOVER % 1.0 F> IF
                            % 4.0 F* FSWAP
                            % 4.0 F* FSWAP
                            % 0.25 scale-factor F!
                          ELSE
                            % 0.25 F* FSWAP
                            % 0.25 F* FSWAP
                            % 4.0 scale-factor F!
                          THEN
;

: zabs-for-small-y ( -- , f: x y -- z )
                 FOVER FOVER F/
                 FDUP FDUP F*
                 % 1.0 F+ FSQRT
                 F+ F/ F+
;

: zabs-for-mid-xy ( -- , f: x y -- z )
                FOVER FOVER F- FOVER F/
                FDUP FDUP % 2.0 F+ F*
                FDUP % 2.0 F+ FSQRT

                sqrt2.0 F+
                F/
                little-bits F+
                F+
                % 2.4142 F+
                F/ F+
;

: normalize ( -- , f: z -- z )
       scale-factor F@ F*
;

: zero-divide-error   FDROP FDROP FDROP FDROP ." zero divide error" ABORT ;

: smaller-real-div ( -- , f: x1 y1 x2 y2 -- x3 y3 )
       FOVER FOVER F/
       FROT FOVER F* FROT F+

       FDUP F0= IF zero-divide-error
                ELSE
                   scale-factor F!
                   FROT FOVER FOVER F* t-real F!
                   FROT FDUP t-real F@ F+ scale-factor F@ F/ t-real F!
                   FROT F* FSWAP F- scale-factor F@ F/
                   t-real F@ FSWAP
                THEN
;

: smaller-imag-div ( -- , f: x1 y1 x2 y2 -- x3 y3 )
       FSWAP FOVER FOVER F/
       FROT FOVER F* FROT F+

       FDUP F0= IF zero-divide-error
                ELSE
                   scale-factor F!
                   FROT FOVER FOVER F* t-imag F!
                   FROT FDUP t-imag F@ F- scale-factor F@ F/ t-imag F!
                   FROT F* F+ scale-factor F@ F/
                   t-imag F@
                THEN

;

: ZABS-SCALED ( -- , f: x y -- z )

         % 0.0 scale-factor F!
         zabs-xy

         FOVER F0= IF FDROP
                   ELSE
                        set-scale-factor
                        FOVER FOVER FOVER FSWAP F-
                        F= IF FDROP
                           ELSE
                               FOVER FOVER F-
                               FOVER
                               F< IF
                                      zabs-for-small-y
                                   ELSE
                                      zabs-for-mid-xy
                                   THEN
                           THEN
                   THEN

;

[THEN]

Public:

2 FLOATS CONSTANT COMPLEX                 \ the size of the type

: Z@  ( addr -- ) ( f: -- re im )    DUP F@ FLOAT+ F@ ;

: Z!  ( addr -- ) ( f: re im -- )    DUP FLOAT+ F! F! ;


: ZDUP ( -- ) ( f: re im -- re im re im )     FOVER FOVER ;

: ZSWAP ( -- ) ( f: x1 y1 x2 y2 -- x2 y2 x1 y1 )
             FRAME| a b c d |   b a d c |FRAME

;

: ZDROP ( -- ) ( f: re im -- )      FDROP FDROP ;

: REAL ( -- ) ( f: re im -- re )     FDROP ;

: IMAG ( -- ) ( f: re im -- im )     FSWAP FDROP ;

: ZCONJUGATE ( -- ) ( f: re im -- re -im )   FNEGATE ;

: REAL>Z  ( -- ) ( f: x -- re im )   % 0.0   ;        \ convert float to complex


: Z->R,I ( -- ) ( F: x y -- re im )     ; IMMEDIATE
: Z->I,R ( -- ) ( F: x y -- im re )   FSWAP ;
: R,I->Z ( -- ) ( F: x y -- re im )     ; IMMEDIATE
: I,R->Z ( -- ) ( F: x y -- im re )   FSWAP ;

\ convert float to pure imaginary complex value
: IMAG>Z ( -- ) ( F: r -- z )         0.0e0 FSWAP ;


: ZVARIABLE
      CREATE FALIGN COMPLEX ALLOT
      DOES>  FALIGNED
;


: ZCONSTANT
      CREATE FALIGN FSWAP F, F,  \ Note: assumes that F, does an FALIGN !
      DOES> FALIGNED Z@
;

: Z.   FSWAP ." ( " F. F. ." ) " ;


: }ZPRINT  ( n addr -- )              \ for printing complex arrays
         SWAP 0 DO I PRINT-WIDTH @ MOD 0= I AND IF CR THEN
                   DUP I } Z@ Z. LOOP
         DROP
;


\ get the next two real numbers as a complex number
: Z%      POSTPONE %   POSTPONE %  ; IMMEDIATE



\ useful complex constants

Z% 1.0 0.0 ZCONSTANT 1+0i
Z% 0.0 0.0 ZCONSTANT 0+0i
Z% 0.0 1.0 ZCONSTANT 0+1i



: Z+ ( -- , f: z1 z2 -- z3 )

            FROT F+
            FROT FROT F+

            I,R->Z
;

: Z- ( -- , f: z1 z2 -- z3 )

            FROT F-
            FROT FROT F-
            I,R->Z
;


: Z* ( --, f: z1 z2 -- z3 )
             t-imag F!   t-real F!

             FOVER t-real F@ F*
             FOVER t-imag F@ F* F-
             FROT FROT

             t-real F@ F* FSWAP
             t-imag F@ F* F+

             R,I->Z
;


PLAUGER-CODE? [IF]

: ZABS ( -- , f: z1 -- r )
	    Z->R,I

            ZABS-SCALED
            normalize
;

: Z/ ( -- , f: z1 z2 -- z3 )

         FOVER FABS FOVER FABS
         F< IF   smaller-real-div
            ELSE smaller-imag-div
            THEN

         R,I->Z
;


[ELSE]

: ZABS ( -- , f: z1 -- r )
	Z->R,I
	FDUP F* FSWAP FDUP F* F+  FSQRT
;

: Z/ ( -- , f: z1 z2 -- z3 )

	ZDUP

	Z->R,I
        FDUP F* FSWAP FDUP F* F+ scale-factor F!

	Z->R,I
	t-imag F!   t-real F!

        Z->R,I
	FOVER t-real F@ F*
        FOVER t-imag F@ F* F+   scale-factor F@ F/

	FROT t-imag F@ F* FNEGATE
        FROT t-real F@ F* F+    scale-factor F@ F/

	R,I->Z

;



[THEN]

Reset_Search_Order





