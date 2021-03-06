(QL:QUICKLOAD '(DATE-CALC))

(DEFPARAMETER *DAY-ROW* "SU MO TU WE TH FR SA")
(DEFPARAMETER *CALENDAR-MARGIN* 3)

(DEFUN MONTH-TO-WORD (MONTH)
  "TRANSLATE A MONTH FROM 1 TO 12 INTO ITS WORD REPRESENTATION."
  (SVREF #("JANUARY" "FEBRUARY" "MARCH" "APRIL"
           "MAY" "JUNE" "JULY" "AUGUST"
           "SEPTEMBER" "OCTOBER" "NOVEMBER" "DECEMBER")
         (1- MONTH)))

(DEFUN MONTH-STRINGS (YEAR MONTH)
  "COLLECT ALL OF THE STRINGS THAT MAKE UP A CALENDAR FOR A GIVEN
MONTH AND YEAR."
  `(,(DATE-CALC:CENTER (MONTH-TO-WORD MONTH) (LENGTH *DAY-ROW*))
     ,*DAY-ROW*
     ;; WE CAN ASSUME THAT A MONTH CALENDAR WILL ALWAYS FIT INTO A 7 BY 6 BLOCK
     ;; OF VALUES. THIS MAKES IT EASY TO FORMAT THE RESULTING STRINGS.
     ,@ (LET ((DAYS (MAKE-ARRAY (* 7 6) :INITIAL-ELEMENT NIL)))
          (LOOP :FOR I :FROM (DATE-CALC:DAY-OF-WEEK YEAR MONTH 1)
             :FOR DAY :FROM 1 :TO (DATE-CALC:DAYS-IN-MONTH YEAR MONTH)
             :DO (SETF (AREF DAYS I) DAY))
          (LOOP :FOR I :FROM 0 :TO 5
             :COLLECT
             (FORMAT NIL "~{~:[  ~;~2,D~]~^ ~}"
                     (LOOP :FOR DAY :ACROSS (SUBSEQ DAYS (* I 7) (+ 7 (* I 7)))
                        :APPEND (IF DAY (LIST DAY DAY) (LIST DAY))))))))

(DEFUN CALC-COLUMNS (CHARACTERS MARGIN-SIZE)
  "CALCULATE THE NUMBER OF COLUMNS GIVEN THE NUMBER OF CHARACTERS PER
COLUMN AND THE MARGIN-SIZE BETWEEN THEM."
  (MULTIPLE-VALUE-BIND (COLS EXCESS)
      (TRUNCATE CHARACTERS (+ MARGIN-SIZE (LENGTH *DAY-ROW*)))
    (INCF EXCESS MARGIN-SIZE)
    (IF (>= EXCESS (LENGTH *DAY-ROW*))
        (1+ COLS)
        COLS)))

(DEFUN TAKE (N LIST)
  "TAKE THE FIRST N ELEMENTS OF A LIST."
  (LOOP :REPEAT N :FOR X :IN LIST :COLLECT X))

(DEFUN DROP (N LIST)
  "DROP THE FIRST N ELEMENTS OF A LIST."
  (COND ((OR (<= N 0) (NULL LIST)) LIST)
        (T (DROP (1- N) (CDR LIST)))))

(DEFUN CHUNKS-OF (N LIST)
  "SPLIT THE LIST INTO CHUNKS OF SIZE N."
  (ASSERT (> N 0))
  (LOOP :FOR X := LIST :THEN (DROP N X)
     :WHILE X
     :COLLECT (TAKE N X)))

(DEFUN PRINT-CALENDAR (YEAR &KEY (CHARACTERS 80) (MARGIN-SIZE 3))
  "PRINT OUT THE CALENDAR FOR A GIVEN YEAR, OPTIONALLY SPECIFYING
A WIDTH LIMIT IN CHARACTERS AND MARGIN-SIZE BETWEEN MONTHS."
  (ASSERT (>= CHARACTERS (LENGTH *DAY-ROW*)))
  (ASSERT (>= MARGIN-SIZE 0))
  (LET* ((CALENDARS (LOOP :FOR MONTH :FROM 1 :TO 12
                       :COLLECT (MONTH-STRINGS YEAR MONTH)))
         (COLUMN-COUNT (CALC-COLUMNS CHARACTERS MARGIN-SIZE))
         (TOTAL-SIZE (+ (* COLUMN-COUNT (LENGTH *DAY-ROW*))
                        (* (1- COLUMN-COUNT) MARGIN-SIZE)))
         (FORMAT-STRING (CONCATENATE 'STRING
                                     "~{~A~^~" (WRITE-TO-STRING MARGIN-SIZE) ",0@T~}~%")))
    (FORMAT T "~A~%~A~%~%"
            (DATE-CALC:CENTER "[SNOOPY]" TOTAL-SIZE)
            (DATE-CALC:CENTER (WRITE-TO-STRING YEAR) TOTAL-SIZE))
    (LOOP :FOR ROW :IN (CHUNKS-OF COLUMN-COUNT CALENDARS)
       :DO (APPLY 'MAPCAR
                  (LAMBDA (&REST HEADS)
                    (FORMAT T FORMAT-STRING HEADS))
                  ROW))))
