{ ====================================================================
SWOOP - Object oriented programming.

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

This is the original version of SWOOP.  It has been replaced by ASWOOP.

==================================================================== }

{ --------------------------------------------------------------------
The following words are optimized in swoopopt.f.  These less efficient
versions are used if swoopopt.f is not present.

Classes return their xt when executed. A class's xt is considered to
be its handle. All class operations are based on this handle.

User variables:
  'THIS has the handle of the current class and
  'SELF has the address of the current object.

THIS returns the handle of the current class and
SELF returns the address of the current data object, normally used
   only while defining a class.

>THIS writes a new value into 'THIS and
>SELF writes a new value into 'SELF.

>C C>  >S S>  are compiler macros which preserve the values of 'THIS
and 'SELF respectively.  They are used in pairs around code sequences.

>C C> save, set, and restore 'THIS.   "THIS >R >THIS ... R> >THIS"
>S S> save, set, and restore 'SELF.   "SELF >R >SELF ... R> >SELF"

>DATA returns a data address for the xt of an object
-------------------------------------------------------------------- }

[UNDEFINED] >THIS [IF]

: THIS ( -- class )   'THIS @ ;
: SELF ( -- object )   'SELF @ ;

: >THIS ( class -- )   'THIS ! ;
: >SELF ( object -- )   'SELF ! ;

: >C ( class -- )
   POSTPONE THIS POSTPONE >R POSTPONE >THIS ; IMMEDIATE

: C> ( -- )
   POSTPONE R> POSTPONE >THIS ; IMMEDIATE

: >S ( object -- )
   POSTPONE SELF POSTPONE >R POSTPONE >SELF ; IMMEDIATE

: S> ( -- )
   POSTPONE R> POSTPONE >SELF ; IMMEDIATE

: >DATA ( xt -- object )   >BODY 3 CELLS + ;

[THEN]


PACKAGE OOP

THROW#
   S" Not an object"            >THROW ENUM IOR_OOP_NOTOBJ
   S" No member (resolve)"      >THROW ENUM IOR_OOP_NORESOLVE
   S" No member (sendmsg)"      >THROW ENUM IOR_OOP_NOSENDMSG
   S" No member (calling)"      >THROW ENUM IOR_OOP_NOCALLING
   S" Not a member"             >THROW ENUM IOR_OOP_NOTMEMBER

TO THROW#

{ --------------------------------------------------------------------
CSTATE has the class handle while we are defining a class.

"SELF" is a compiler tool to emplace a reference to SELF before
   each class-local item while compiling the class. This makes the
   code look nicer; instead of SELF X @ one can just say X @ .
   Pronounce this by wiggling two fingers on each hand in the air
   while saying the word SELF.

"THIS" emplaces a reference to the current class as necessary for
   resolving defer methods or simply executing a class member.
-------------------------------------------------------------------- }

VARIABLE CSTATE

: "SELF" ( -- )
   CSTATE @ -EXIT  CSTATE @ THIS <> ?EXIT  POSTPONE SELF ;

: "THIS" ( -- )   CSTATE @ IF
      CSTATE @ THIS = IF  POSTPONE THIS  EXIT  THEN
   THEN  THIS POSTPONE LITERAL ;

{ --------------------------------------------------------------------
We manage our object system with two system wordlists.

CC-WORDS has the defining words used while building classes and
MEMBERS has the unique identifiers for class members.

+MEMBERS adds the MEMBERS wordlist to the search order and
-MEMBERS removes it from the search order.

+CC puts MEMBERS and CC-WORDS on the top of the search order and
-CC removes them from the search order.
-------------------------------------------------------------------- }

PUBLIC

WORDLIST CONSTANT CC-WORDS
WORDLIST CONSTANT MEMBERS

: +MEMBERS ( -- )   MEMBERS +ORDER ;
: -MEMBERS ( -- )   MEMBERS -ORDER ;

PRIVATE

: +CC ( -- )   +MEMBERS CC-WORDS +ORDER ;
: -CC ( -- )   -MEMBERS CC-WORDS -ORDER ;

{ --------------------------------------------------------------------
Classes are:

| link | xt | super | public | protected | private | anonymous | size | objects | tag |

>SUPER etc traverse this structure from the class handle.

SIZEOF returns the size of the specified class.

|CLASS| is how many cells are required to define a class.

CLASSTAG is a marker derived from the xt of |CLASS|.
-------------------------------------------------------------------- }

: BODY+ ( n "name" -- n+1 )
   CREATE DUP CELLS , 1+ DOES> @ SWAP >BODY + ;

0 BODY+ >CLINK          \ linked list of classes
  BODY+ >CHANDLE        \ handle of this class, its xt
  BODY+ >SUPER          \ handle of its parent
  BODY+ >PUBLIC         \ public message list
  BODY+ >PROTECTED      \ protected message list
  BODY+ >PRIVATE        \ private message list
  BODY+ >ANONYMOUS      \ windows (anonymous) message list
  BODY+ >ANONYMOUS2     \ another for the command list
  BODY+ >ANONYMOUS3     \ another for the dialog command list
  BODY+ >SIZE           \ size of the class in bytes
  BODY+ >OBJCHAIN       \ the chain of objects defined in the class
  BODY+ >CLASSTAG       \ a tag to prove it is a class
CONSTANT |CLASS|        \ how big a class data structure is

PUBLIC

' |CLASS| CONSTANT CLASSTAG
' |CLASS| 1+ CONSTANT OBJTAG

: SIZEOF ( class -- n )   >SIZE @ ;

PRIVATE


{ --------------------------------------------------------------------
Executing a named class returns its xt, which is its handle.

When a class is created, THIS will contain the handle of the class
until END-CLASS is executed.

CLASSES has the list of all known classes.
OPAQUE has 0 if new members are PUBLIC, 1 if new members are PROTECTED,
   and 2 if new members are PRIVATE.  This is an offset, translated into
   cells from >PUBLIC when used in NEW-MEMBER.

CLASS defines a new class.  With
SUBCLASS, we use
INHERITS to build a new class from an existing one.
RE-OPEN allows further refinements of a class.
RELINK fixes the links in a child after its parent is extended
   with RE-OPEN.

SUPREME is the mother of all classes. Members may be added to
   it with extreme care.
-------------------------------------------------------------------- }

CHAIN CLASSES

VARIABLE OPAQUE

: RE-OPEN  ( class -- )  DUP >THIS  CSTATE !  0 OPAQUE !  +CC ;

: (CLASS) ( -- )   CREATE-XT ( xt) DUP RE-OPEN
   CLASSES <LINK  ( xt) , |CLASS| 2 - CELLS /ALLOT CLASSTAG ,
   DOES> CELL+ @ ;

PUBLIC

(CLASS) SUPREME   -MEMBERS -CC

PRIVATE

: INHERITS ( class -- )
   HERE CELL- @ CLASSTAG <> ABORT" INHERITS must follow CLASS <name>"
   |CLASS| 1- CELLS NEGATE ALLOT   \ forget all except link.
   DUP ,                           \ point superclass field to new parent.
   DUP >PUBLIC @REL ,REL           \ inherit public
   DUP >PROTECTED @REL ,REL        \ and protected.
   0 ,                             \ never inherit private.
   DUP >ANONYMOUS @REL ,REL        \ inherit anonymous.
   DUP >ANONYMOUS2 @REL ,REL       \ inherit anonymous.
   DUP >ANONYMOUS3 @REL ,REL       \ inherit anonymous.
   DUP SIZEOF ,                    \ inherit size.
   DUP >OBJCHAIN @REL ,REL         \ inherit object chain
   CLASSTAG ,                      \ mark this as a class.
   DROP ;

: UPDATE-LINKS ( super link -- )   >R
   BEGIN
      DUP @REL DUP WHILE                \ prev cur
      R@ BEGIN                          \ prev cur sup
         @REL DUP WHILE                 \ prev cur sup'
         2DUP = UNTIL
         2DROP  R> @REL SWAP !REL  EXIT
      THEN DROP NIP
   REPEAT R> DROP  2DROP ;

PUBLIC

: RELINK ( class -- )   DUP >SUPER @ SWAP 2>R
   2R@ >PUBLIC     SWAP >PUBLIC     UPDATE-LINKS
   2R@ >PROTECTED  SWAP >PROTECTED  UPDATE-LINKS
   2R@ >ANONYMOUS  SWAP >ANONYMOUS  UPDATE-LINKS
   2R@ >ANONYMOUS2 SWAP >ANONYMOUS2 UPDATE-LINKS
   2R@ >ANONYMOUS3 SWAP >ANONYMOUS3 UPDATE-LINKS
   2R> 2DROP ;

: REOPEN ( class -- )   DUP RELINK  RE-OPEN ;

: CLASS ( -- )
   (CLASS) SUPREME INHERITS ;

: SUBCLASS ( class -- )
   (CLASS) INHERITS ;

PRIVATE

{ --------------------------------------------------------------------
COMPILE-AN-OBJECT compiles a reference that returns the object's
   address generated by the given xt and adds MEMBERS to the search order.

INTERPRET-AN-OBJECT returns an object's address.

(OBJECT) compiles or executes an object reference.

BUILDS creates a named object which looks like:
      | xt | objtag | class | data.... |

USING sets the class search order so that the MEMBERS wordlist is active.
   The net result is to allow the use of arbitrary class methods on an
   arbitrary address in memory.
-------------------------------------------------------------------- }

: COMPILE-AN-OBJECT ( addr xt -- )  >R
   @+ POSTPONE LITERAL R> COMPILE,  CELL+ @ >THIS +MEMBERS ;

: INTERPRET-AN-OBJECT ( addr xt -- addr )   >R
   @+ SWAP CELL+ @ >THIS +MEMBERS  R> EXECUTE ;

: (OBJECT) ( addr xt -- | addr )
   STATE @ IF COMPILE-AN-OBJECT ELSE INTERPRET-AN-OBJECT THEN ;

PUBLIC

: BUILDS ( class -- )
   CREATE-XT IMMEDIATE ( xt) , OBJTAG , ( class) DUP ,  SIZEOF /ALLOT
   DOES> ['] >DATA  (OBJECT) ;

: USING ( -- )   ' DUP  >CLASSTAG @
   CLASSTAG <> ABORT" Class name must follow USING"
   >THIS +MEMBERS ; IMMEDIATE

PRIVATE

{ --------------------------------------------------------------------
A class has four member lists associated with it: public, protected,
private, and anonymous.  These lists indicate which messages the
class recognizes and how to compile and/or execute the member when
referenced. The format of these lists is

   | compiler-xt | link | member handle | runtime-xt | data | ...

The data field varies from method to method. This is documented
below in the METHODS section.

The structure of the member list contains an embedded switch statement;
the link|member|xt pattern.

A member handle represents a valid member if it is in the MEMBERS
wordlist and either the public, protected, or private member list of the
current class. This represents the namespace of the class.

NEW-MEMBER builds a list entry for the current class associating the
   member with compiler and runtime xts and a single data value. The
   member goes into a list controlled by OPAQUE: If OPAQUE is positive,
   it represents the offset of cells from >PUBLIC; if negative, it
   forces the entry into >ANONYMOUS.  This is controlled by just the
   high bit of OPAQUE, which is always cleared here.

BELONGS? returns the address of link if the member belongs to the
   current class.  BELONGS? should be coded for speed, as it is in the
   critical path for virtual methods.

PUBLIC? searches the public list,
PROTECTED? searches the protected list, and
PRIVATE? searches the private list of THIS .

CLASS-MEMBER? checks THIS class for the member. Used by RESOLVED, for
   virtual members (DEFER:) and so doesn't check PRIVATE.

VISIBLE-MEMBER? checks the member lists of THIS class for the member.
   Since this is the action of all members, it must function both
   during class compilaion and during method reference in normal
   compilation.

   If THIS is zero, it fails; no class is current to search.

   If CSTATE is non-zero, we are compiling a class.
   If CSTATE=THIS, the reference is to the current class; search
      public, protected, and private.
   If CSTATE<>THIS, the reference is to another class; search
      public and protected, but not private.

MEMBER? checks the specified class for the member id on the stack.
-------------------------------------------------------------------- }

: NEW-MEMBER ( member data runtime-xt compiler-xt -- )
   ALIGN   LOCATION ,  ,  OPAQUE @ 0< IF
      THIS >ANONYMOUS  OPAQUE @ 24 RSHIFT $7F AND CELLS +
   ELSE THIS >PUBLIC  OPAQUE @ CELLS + THEN  >LINK
   ROT , , ,
   OPAQUE @ $00FFFFFF AND OPAQUE ! ;

: BELONGS?   ( member list -- 'member true | member false )
   BEGIN
      @REL DUP WHILE
      2DUP CELL+ @ =
   UNTIL NIP TRUE
   THEN  ;

: PUBLIC? ( member -- 'member true | member 0 )
   THIS >PUBLIC BELONGS? ;

: PROTECTED? ( member -- 'member true | member 0 )
   THIS >PROTECTED BELONGS? ;

: PRIVATE? ( member -- 'member true | member 0 )
   THIS >PRIVATE BELONGS? ;

: CLASS-MEMBER? ( member -- 'member true | 0 )
   THIS IF
      PUBLIC?    DUP ?EXIT DROP
      PROTECTED? DUP ?EXIT DROP
   THEN DROP 0 ;

: VISIBLE-MEMBER? ( member -- 'member true | 0 )
   THIS IF                              \ class is selected
      PUBLIC? DUP ?EXIT DROP            \ exit if in public
      CSTATE @ IF                       \ compiling a class
         PROTECTED? DUP ?EXIT DROP      \ exit if in protected
         CSTATE @ THIS = IF             \ compiling this class
            PRIVATE? DUP ?EXIT DROP     \ exit if in private
         THEN                           \
      THEN                              \ else normal forth reference
   THEN DROP 0 ;                        \ failing

: MEMBER? ( member class -- 'member true | member 0 )
   2DUP >PUBLIC     BELONGS? IF NIP NIP -1 EXIT THEN DROP
   2DUP >ANONYMOUS  BELONGS? IF NIP NIP -1 EXIT THEN DROP
        >ANONYMOUS2 BELONGS? ;

{ --------------------------------------------------------------------
EARLY-BINDING executes the compiler-xt of the given member, which
   compiles a reference to it according to the member type.

LATE-BINDING executes the runtime-xt of the given member.  All
   members require an object address on the stack when executing.
   This is used for runtime binding (i.e., true late binding) and
   for Forth interpreter access.

REFERENCE-MEMBER either compiles or executes a member.

?OBJECT throws if the entity whose address is on the stack is not
   an object.

IS-OBJECT tests the entity to make sure it is an object.

SENDMSG executes the given member id in the context of the class to
   which the object belongs. This is considered to be sending a
   message.

RESOLVED looks up the member in the current class and executes it.
   This is used at runtime for late binding of virtual functions.
   We search from the class pointed to by THIS at runtime, and the
   first member match we find is executed. If no better behavior is
   defined than the initial DEFER:, we will find that and execute
   it by default.

-------------------------------------------------------------------- }

: EARLY-BINDING ( 'member -- )
   DUP 3 CELLS +  SWAP CELL - @ EXECUTE ;

\ : LATE-BINDING ( object 'member -- )
\    OVER CELL- @ >THIS  2 CELLS + @+  EXECUTE  ;

CODE LATE-BINDING ( object 'member -- )
   12 # EBX ADD  0 [EBP] EAX MOV
   -4 [EAX] EAX MOV  EAX 'THIS [U] MOV
   -4 [EBX] EAX MOV  EDI EAX ADD  EAX JMP
   RET END-CODE

: REFERENCE-MEMBER ( [object] 'member -- )
   STATE @ IF EARLY-BINDING ELSE
      CSTATE @ IF ( interpreting in a class definition)
         0 SWAP 2 CELLS + @+ EXECUTE
      ELSE
         LATE-BINDING  THIS 0= IF  -MEMBERS  THEN
      THEN
   THEN ;

: IS-OBJECT ( addr -- flag )   2 CELLS - @  OBJTAG = ;

: ?OBJECT ( object -- )
   2 CELLS - @ OBJTAG <> IOR_OOP_NOTOBJ ?THROW ;

: RESOLVED ( member -- )
   CLASS-MEMBER? 0= IOR_OOP_NORESOLVE ?THROW  3 CELLS + @ EXECUTE ;

PUBLIC

: SENDMSG ( object member-id -- )   OVER ?OBJECT
   OVER CELL- @ MEMBER? 0= IOR_OOP_NOSENDMSG ?THROW LATE-BINDING ;

: 'MEMBER ( -- xt flag )
   BL WORD COUNT MEMBERS SEARCH-WORDLIST ;

: CALLING ( -- )
   'MEMBER 0= IOR_OOP_NOCALLING ?THROW  STATE @ IF
      POSTPONE LITERAL  POSTPONE SENDMSG
   ELSE  SENDMSG THEN ; IMMEDIATE

: -> ( -- )   POSTPONE CALLING ; IMMEDIATE

PRIVATE

{ --------------------------------------------------------------------
Each class has a namespace of members which belong to it. Members
exist as unique identifiers in a single wordlist. All are
immediate. All know their own XT, which is used as a unique
identifier for a method name.

DO-MEMBER is the execution behavior of a member. This is complicated
   by the need to re-cast the xt for non-class evaluation if
   it is a member, but not a member of THIS class.

CREATE-MEMBER makes a new member in THIS class' namespace.  The member
   knows its xt and name -- because these are kept in its body.

MEMBER is a defining word which a) returns the xt of an existing
   member or b) creates a new member and returns its xt.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
0 [IF] ( this is the ans version)

: DO-NONMEMBER ( addr -- )
   -MEMBERS FIND DUP IF
      0< STATE @ 0<> AND IF COMPILE, ELSE EXECUTE THEN
      CSTATE @ IF +MEMBERS ELSE 0 >THIS  THEN   EXIT THEN
   DROP  COUNT TYPE  ."  not found" 0 >THIS  -1 THROW ;

: DO-MEMBER ( member-addr -- )   @+ VISIBLE-MEMBER? IF
      NIP REFERENCE-MEMBER  EXIT THEN
   DO-NONMEMBER ;

: CREATE-MEMBER ( -- xt )
   >IN @ >R   CREATE-XT IMMEDIATE ( xt) DUP ,   R> >IN !
   BL WORD COUNT STRING,  DOES> DO-MEMBER ;

[ELSE] ( this is the swiftforth version)
-------------------------------------------------------------------- }

: DO-NONMEMBER ( addr -- )   -MEMBERS
   COUNT  STATE @ IF WORD-COMPILER ELSE WORD-INTERPRETER THEN
   CSTATE @ IF +MEMBERS ELSE 0 >THIS  THEN ;

: (COMMON) ( -- )
   0 >C  -CC  BL WORD DO-NONMEMBER  +CC  C> ;

: DO-MEMBER ( member-addr -- )
   BODY> DUP VISIBLE-MEMBER? IF
      NIP REFERENCE-MEMBER  EXIT THEN
   >NAME DO-NONMEMBER ;

: CREATE-MEMBER ( -- xt )   CREATE-XT IMMEDIATE DOES> DO-MEMBER ;

PUBLIC

: [MEMBER] ( -- xt )
   'MEMBER 0= IOR_OOP_NOTMEMBER ?THROW
   STATE @ IF POSTPONE LITERAL THEN ;  IMMEDIATE

: MEMBER ( -- xt )
   >IN @  'MEMBER IF  NIP EXIT  THEN  >IN !
   GET-CURRENT >R  MEMBERS SET-CURRENT
   ['] CREATE-MEMBER CATCH R> SET-CURRENT THROW ;

MEMBER CONSTRUCT DROP
MEMBER DESTRUCT  DROP

PRIVATE

{ --------------------------------------------------------------------
NEW is the dynamic object constructor and
DESTROY is the corresponding destructor.
-------------------------------------------------------------------- }

: DOMSG ( class object member-id -- )
   ROT >C  PUBLIC?  0= IOR_OOP_NOTMEMBER ?THROW
   2 CELLS + @+ EXECUTE    C> ;

: BROADCAST ( class object message -- )   2>R
   DUP >OBJCHAIN BEGIN
      @REL ?DUP WHILE  DUP
      2 CELLS - 2@ 2R@ >R + R> RECURSE
   REPEAT  2R> DOMSG ;

PUBLIC

: NEW ( class -- addr )
   DUP SIZEOF CELL+ CELL+ ALLOCATE THROW OBJTAG !+ OVER !+
   TUCK ( a c a) [MEMBER] CONSTRUCT BROADCAST ;

: DESTROY ( addr -- )
   DUP  CELL- @  OVER [MEMBER] DESTRUCT BROADCAST
   CELL- CELL- FREE THROW ;

: CONSTRUCT-OBJECT ( object -- )
   DUP IS-OBJECT IF
      CELL- @+ SWAP [MEMBER] CONSTRUCT BROADCAST EXIT
   THEN DROP ;

: DESTRUCT-OBJECT ( object -- )
   DUP IS-OBJECT IF
      CELL- @+ SWAP [MEMBER] DESTRUCT BROADCAST EXIT
   THEN DROP ;

PRIVATE

{ --------------------------------------------------------------------
Late binding behaviors

When members are explicitly referenced at runtime, these are the
routines that are called for the different type objects.  RUN-COLON
is used for both the colon and defer types.

RUN-DATA adds the offset in the member list data field to the object
   whose base address is on the stack.

RUN-OBJECT sets the current class according to the

-------------------------------------------------------------------- }

: RUN-DATA ( object 'data -- addr )   @ +  0 >THIS ;

: RUN-OBJECT ( object 'data -- addr )   2@  SWAP >THIS  + ;

: RUN-COLON ( object 'data -- )
   SWAP >S THIS >C  @ EXECUTE  C> S> 0 >THIS ;

{ --------------------------------------------------------------------
Early binding compilers

When members are referenced at compile time, code to execute a specfic
behavior is compiled.  Each of the different member types needs its
own early binding compiler.

Terminal methods, which are the final member name in a phrase, clear
the class namespace from the Forth search order.

Rreferences to an embedded objects are not terminal, but change the
active namespace to reflect the class which defined the object.

END-REFERENCE removes the class namespace from the Forth search order.

COMPILE-OBJECT compiles  "SELF" LIT +  and changes the namespace.

COMPILE-DATA compiles  "SELF" LIT +  .

COMPILE-COLON compiles  "SELF" >S "THIS" >C xt C> S>  .

COMPILE-DEFER compiles   "SELF" >S "THIS" >C member RESOLVED C> S>  .
-------------------------------------------------------------------- }

: END-REFERENCE ( -- )
   CSTATE @ DUP >THIS  ?EXIT -MEMBERS ;

: COMPILE-OBJECT ( 'data -- )   "SELF"
   2@ ?DUP IF POSTPONE LITERAL POSTPONE + THEN  >THIS +MEMBERS ;

: COMPILE-DATA ( 'data -- )   "SELF"   \ 'data: offset
   @ ?DUP IF POSTPONE LITERAL POSTPONE + THEN  END-REFERENCE ;

: PRE-COLON  ( -- )   "SELF"  POSTPONE >S  "THIS" POSTPONE >C ;
: POST-COLON ( -- )   POSTPONE C>  POSTPONE S>  END-REFERENCE ;

: COMPILE-COLON ( object 'data -- )   PRE-COLON
   @ COMPILE, POST-COLON ;

: COMPILE-DEFER ( object 'data -- )   PRE-COLON
   2 CELLS - @ POSTPONE LITERAL POSTPONE RESOLVED  POST-COLON ;

{ --------------------------------------------------------------------
PRIVATE, PROTECTED, and PUBLIC set which kind of members follow.
Private words are bracketed by PRIVATE ... PUBLIC  or  PRIVATE ...
PROTECTED. Protected words are bracketed by PROTECTED ... PUBLIC  or
PROTECTED  ... PRIVATE

END-CLASS concludes a class definition by clearing CSTATE and restoring
   the search order as best it can.

BUFFER: reserves n bytes of data space in the current class.

MESSAGE: compiles a message switch in a class definition.  The high
   bit of OPAQUE is set to force the member entry into the messages
   list.  NEW-MEMBER clears this bit.

DEFER: compiles a virtual member for the current class that has a
   default behavior. Used like a colon definition.  When a reference
   to the routine is made, it will late-bind in the current class
   or subclass for a more recently defined version (defined via :)
   and execute that if found. Otherwise, it will execute its default
   behavior.  The stack effect for all routines with the same name
   should be the same!

: defines a new executable member which
; terminates. Just like Forth!

BUILDS creates an embedded object of a specific class in the current
   class. When referenced, all methods of its class are available.

SUPER allows the reference of a parent's member.
COMMON allows access to a word in the underlying system that has
   been obscured by a class member.
-------------------------------------------------------------------- }

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : PUBLIC    ( -- )   0 OPAQUE ! ;
   : PROTECTED ( -- )   1 OPAQUE ! ;
   : PRIVATE   ( -- )   2 OPAQUE ! ;

   : END-CLASS ( -- )   0 RE-OPEN  -CC ;

   : SUPER ( -- )
      THIS >SUPER @ >THIS POSTPONE SELF ; IMMEDIATE

   : COMMON  (COMMON) ; IMMEDIATE
   : ::      (COMMON) ; IMMEDIATE

   : BUFFER: ( n -- )   MEMBER  THIS SIZEOF
      ['] RUN-DATA ['] COMPILE-DATA  NEW-MEMBER  DUP ,
      THIS >SIZE +! ;

   : VARIABLE ( -- )   THIS SIZEOF ALIGNED THIS >SIZE !
      [ +CC ] CELL BUFFER: [ -CC ] ;

   : HVARIABLE ( -- )   THIS SIZEOF ALIGNED THIS >SIZE !
      [ +CC ] 2 BUFFER: [ -CC ] ;

   : CVARIABLE ( -- )
      [ +CC ] 1 BUFFER: [ -CC ] ;

   : MESSAGE: ( id -- member class-sys colon-sys )
      OPAQUE @ $80000000 OR OPAQUE !
      ['] RUN-COLON ['] COMPILE-COLON  :NONAME ;

   : COMMAND: ( cmdid -- member class-sys colon-sys )
      OPAQUE @ $81000000 OR OPAQUE !
      ['] RUN-COLON ['] COMPILE-COLON  :NONAME ;

   : DIALOG: ( cmdid -- member class-sys colon-sys )
      OPAQUE @ $82000000 OR OPAQUE !
      ['] RUN-COLON ['] COMPILE-COLON  :NONAME ;

   : DEFER: ( -- member runtime compiler colon-sys )
      OPAQUE @ 0 2 WITHIN 0= ABORT" Can't DEFER: in private"  MEMBER
      ['] RUN-COLON ['] COMPILE-DEFER  :NONAME ;

   : : ( -- member class-sys colon-sys )   MEMBER
      ['] RUN-COLON ['] COMPILE-COLON  :NONAME ;

   : ; ( member runtime compiler colon-sys -- )
      POSTPONE ; ROT ROT  NEW-MEMBER ; IMMEDIATE

   : BUILDS ( class -- )      MEMBER  THIS SIZEOF
      ['] RUN-OBJECT ['] COMPILE-OBJECT NEW-MEMBER
      ( class) DUP ,  THIS >OBJCHAIN >LINK  1 ,  SIZEOF THIS >SIZE +! ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT


{ ====================================================================
(C) Copyright 1999 FORTH, Inc.   www.forth.com

Examples of extensions
==================================================================== }

{ --------------------------------------------------------------------
OBJ-SIZE returns the size and base address of an object from its xt.

>DATA[] returns the address of the nth object in the array at the xt.

BUILDS[] creates a named array of objects.  The structure of an indexed
   named object in memory is:
      | xt | objtag | class | n | data[0] | data[1] | ... | data[n-1] |
-------------------------------------------------------------------- }

: >DATA[] ( n xt -- object )
   >BODY 2 CELLS + @+ SIZEOF >R ( n 'n)
   @+ 1- ( n 'data n) ROT 0 MAX MIN R> * + ;

PUBLIC

: BUILDS[] ( n class -- )
   CREATE-XT IMMEDIATE ( xt) , OBJTAG , ( class) DUP ,  OVER ,
   SIZEOF  * /ALLOT  DOES> ['] >DATA[] (OBJECT) ;

PRIVATE

{ --------------------------------------------------------------------
Between CLASS and END-CLASS, we want constants to simply return
their value when executed. For instance,
   CLASS FOO
      28 CONSTANT LC
      LC POINT BUILDS[] ARRAY
   END-CLASS
but when accesses interpretively outside class definition, it would
have to be used as
   FOO BUILDS SAM
   SAM LC
which means that an un-necessary object address is on the stack,
present simply to set the context for the named constant. sigh...
This behavior is target compilable because the tc will require a
twin of the constant anyway.

RUN-CONSTANT discards the object address and reads the constant
   from the member list entry.

COMPILE-CONSTANT compiles a forced drop of the required object
   address followed by the literal value of the constant.
-------------------------------------------------------------------- }

: RUN-CONSTANT ( object 'data -- n )
   NIP @ ;

: COMPILE-CONSTANT ( 'data -- )   "SELF"  POSTPONE DROP
   @  POSTPONE LITERAL  END-REFERENCE ;

{ --------------------------------------------------------------------
CREATE has similar problems to CONSTANT when used in a class.

RUN-CREATE discards the object address and skips over the
   unused data field in the member list entry.

COMPILE-CREATE compiles a drop, then compiles a convoluted
   reference to the memory following the member list entry.
   This is necessary, because we can't assume a constant
   address for the runtime system and must generate relocatable
   code.  The only things that are constant are: the distance from
   the body address of the class to the actual address of the
   data, and the handle (xt) of the class to which the data
   belongs.  So, the code, assuming the member entry address
   on the stack, is:

      [ THIS ] LITERAL >BODY [ THIS >BODY - CELL+ ] LITERAL +

-------------------------------------------------------------------- }

: RUN-CREATE ( object 'data -- )
   NIP CELL+ ;

: COMPILE-CREATE ( 'data -- )   "SELF"  POSTPONE DROP
   THIS POSTPONE LITERAL  POSTPONE >BODY
   THIS >BODY - CELL+ POSTPONE LITERAL  POSTPONE +  END-REFERENCE ;

{ --------------------------------------------------------------------
INDEXED[] generates an address from a base given a size and index.

RUN-OBJECT[] resembles RUN-OBJECT, but indexes an array of objects.

COMPILE-OBJECT[] compiles the literal offset to the start of the
   array, then a reference to the INDEXED[] routine for the class.
-------------------------------------------------------------------- }

: INDEXED[] ( n base size -- addr )   ROT * + ;

: RUN-OBJECT[] ( n object 'data -- addr )
   2@  ROT + -ROT  DUP >THIS  SIZEOF * + ;

: COMPILE-OBJECT[] ( 'data -- )   "SELF"
   2@  ?DUP IF POSTPONE LITERAL POSTPONE + THEN
   DUP >THIS  SIZEOF POSTPONE LITERAL POSTPONE INDEXED[] ;

{ --------------------------------------------------------------------
CONSTANT CREATE and BUILDS[] create new member list entries.

CONSTANT uses the data field for the constant value.

CREATE reserves but doesn't use the first cell of the data field; data
   following the CREATE will extend the data field of the entry.

BUILDS[] uses the first cell of the data field for the offset from the
   container's data space start to the array start, and the second
   cell of the data space to hold the class of the contained object.
-------------------------------------------------------------------- }

GET-CURRENT ( *) CC-WORDS SET-CURRENT

   : CONSTANT ( n -- )
      MEMBER SWAP ['] RUN-CONSTANT ['] COMPILE-CONSTANT NEW-MEMBER ;

   : CREATE ( -- )
      MEMBER CELL ['] RUN-CREATE ['] COMPILE-CREATE NEW-MEMBER ;

   : BUILDS[] ( n class -- )   MEMBER  THIS SIZEOF
      ['] RUN-OBJECT[] ['] COMPILE-OBJECT[] NEW-MEMBER
      ( class) DUP ,  THIS >OBJCHAIN >LINK   DUP ,
      SIZEOF * THIS >SIZE +! ;

GET-CURRENT CC-WORDS <> THROW ( *) SET-CURRENT

{ --------------------------------------------------------------------
Here are added a few common words to the SUPREME class to make life
easier.

ADDR returns the address of the object.
CONSTRUCT and DESTRUCT will be automatically sent to an object
   when it is created or destroyed. But not implemented yet...
-------------------------------------------------------------------- }

SUPREME REOPEN

   0 BUFFER: ADDR

   : CONSTRUCT ( -- )   ;
   : DESTRUCT ( -- )   ;

END-CLASS

{ --------------------------------------------------------------------
.CLASSES will display a list of all defined classes. This list should
be inverted and displayed as a tree.
-------------------------------------------------------------------- }

OOP +ORDER

VARIABLE LEVEL

: HANGING ( -- )
   LEVEL @ CASE
        0 OF               ENDOF
        1 OF  ." +- "      ENDOF
      DUP OF  LEVEL @ 1- 0 ?DO  ." |  " LOOP ." +- " ENDOF
   ENDCASE ;

: SHOW-CHILDREN ( class -- )
   CLASSES BEGIN
      @REL ?DUP WHILE   \ address of class, not handle of class!
      2DUP 2 CELLS + @ = IF
         CR HANGING DUP BODY> >NAME .ID
         1 LEVEL +!  DUP BODY> RECURSE  -1 LEVEL +!
      THEN
   REPEAT DROP ;

PUBLIC

: CLASSES ( -- )
   CR ." SUPREME" 1 LEVEL !  SUPREME SHOW-CHILDREN ;

END-PACKAGE


