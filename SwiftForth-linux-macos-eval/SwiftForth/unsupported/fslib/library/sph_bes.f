\  \\\\\\\\\\\\\\\\\\\\\\\\\\\\\ start of file
\ Regular spherical Bessel functions jn(x), n=0-9
\
\ Forth Scientific Library Algorithm #43
\
\ Uses Miller's method of downward recursion, as described
\ in Abramowitz & Stegun, "Handbook of Mathematical Functions"
\ 10.5 ff. The recursion is
\
\     j(n-1) = (2n+1) j(n) / x  - j(n+1)
\
\ The downward recursion is started with j40 = 0, j39 = 1 . The
\ resulting functions are normalized using
\
\     Sum (n=0 to inf) { (2n+1) * jn(x)^2 } = 1 .
\
\ Usage:  % 3 SPHBES  leaves jn(3), n=0-9,
\         in the double-length (64-bit) array JBES{
\
\ Programmed by J.V. Noble
\ ANS Standard Program  -- version of  10/25/1994
\
\ This code conforms with ANS requiring:
\      The FLOAT and FLOAT EXT word sets
\ Environmental dependencies:
\       Assumes independent floating point stack
\       Required: 64-bit IEEE floating point internal storage format
\       If a similar precision but different internal format
\       is used, DF@ and DF! should be replaced by F@ and F!
\       to prevent loss of precision in conversion

\ Note: if 32-bit precision is desired, the sum and the functions
\ must be renormalized at  n = 30, n = 20 and n = 10.
\ Replace REAL*8 by REAL*4, DF@ and DF! by SF@ and SF!

\ Non STANDARD words:
\      2-   : 2-    1-  1-  ;
\      S>F  : S>F   S>D  D>F   ; ( n --) ( F: -- n)
\      F=0  ( puts 0 on fpstack)
\      F=1  ( puts 1 on fpstack)
\      1ARRAY  define a 1-dimensional array
\      }    dereference a one-dimensional array.
\           as in  A{ I }  ( base.adr -- base.adr + offset )
\      %    (IMMEDIATE word) converts the following text
\           to a floating-point literal
\      F**2  : F**2   ( F: x -- x*x)  FDUP  F*  ;
\
\     (c) Copyright 1994  Julian V. Noble.     Permission is granted
\     by the author to use this software for any application provided
\     the copyright notice is preserved.
\
\ Non STANDARD word definitions: these assume no need to FALIGN floating
\     point values.

\  0 CONSTANT REAL*4
\  1 CONSTANT REAL*8
\  2 CONSTANT COMPLEX
\  3 CONSTANT DCOMPLEX

\  CREATE LEN_TAB  2 , 4 , 4 , 8 ,
\  : #CELLS   ( n -- #b)   LEN_TAB  +  @  ;

\ 1-dim array:  A{ I } leaves address of i'th elt of vector A{
\  : 1ARRAY   ( length cells/float --)  CREATE   DUP  ,  *  ALLOT  ;
\  : }   ( x[0] n  -- x[n])   OVER @  *  1+  CELLS  +   ;


\ data structures
\ 10  REAL*8  #CELLS  1ARRAY  JBES{      \ holds j0-j9

\  if using the FSLUTIL.xxx array implementation, replace this with
  10 FLOAT ARRAY  JBES{

FVARIABLE  SUM                         \ temps to off-load from fp stack
FVARIABLE  X 

: SETUP    ( F: x -- 0 1 )  ( -- 79)
     X DF!   79 S>F  SUM DF!
     F=0 F=1    79  ;

: NORMALIZE     SUM  DF@  FSQRT  1/F
      10 0   DO   FDUP   JBES{ I }  DUP  DF@  F*   DF!   LOOP
      FDROP  ;

: DO_X=0    FDROP  F=1  JBES{ 0 } DF!
            10 1  DO    F=0   JBES{ I }   DF!    LOOP   ;

: ITERATE   ( F:  jn+1 jn -- jn jn-1)  ( 2n+1 -- 2n-1)
      DUP  S>F   FOVER  F*      ( F:  jn+1 jn jn*[2n+1] )
      X DF@  F/    FROT  F-      ( F:  -- jn jn-1)
      FDUP  F**2                 ( F:  -- jn jn-1 jn-1^2 )
      2-  DUP                    ( -- 2n-1 2n-1 )
      S>F  F*
      SUM DF@   F+   SUM DF!   ;

: SPHBES  ( F: x --)
      FDUP   F0=
      IF     DO_X=0   EXIT    THEN
      SETUP
      11 39 DO   ITERATE   -1 +LOOP
      0  9  DO   ITERATE
                 FDUP   JBES{ I }  DF!
      -1 +LOOP
      DROP   FDROP  FDROP        \ clean up stacks
      NORMALIZE  ;
\  \\\\\\\\\\\\\\\\\\\ end of file
