;;;; Assignment: Programming Assignment #1: Common Lisp
;;;;


;; Merge Sort

;; This is my implementation of merge sort. It uses two pure functions. mergeSort divides the list 
;; supplied to it in half until it is a singlet list then the two halves are supplied to mergeHelper
;; which merges them into a sorted listed. When mergeHelper reaches its base cases (one or either
;; list supplied to it being empty), it will return a sorted listed that is then returned to earlier
;; mergeHelper calls that operate the same way until the list is completely sorted.

;; This is a helper function for mergeSort. It takes in two lists that are already sorted and
;; combines them together in a sorted manner. The base cases are when either of the lists supplied 
;; to mergeHelper are empty, at that point there are no more comparisons and mergeHelper can just
;; return the list that's not empty because it's been adequately sorted and combined. 
(defun mergeHelper (xs ys)
  "merge two sorted lists."
  (let ((xhead (car xs))                           ; xhead/yhead are the cars of xs/ys. they'll be compared later in the
        (xtail (cdr xs))                           ;   function.
        (yhead (car ys))                           ; xtail/ytail are the remainders of xs/ys. in some cond branches they get
        (ytail (cdr ys)))                          ;   passed to mergeHelper to further traverse the lists xs and ys.
    (cond ((null xs) ys)                           ; base cases. if xs/ys happens to be empty, return the other. the lists 
          ((null ys) xs)                           ;   are combined/sorted.
          ((> xhead yhead)                         ; if xhead > yhead, then yhead is before xhead in the list. It's unknown  
           (cons yhead (mergeHelper xs ytail)))    ;   if xhead is greater than the next element in ys, so we apply 
                                                   ;   mergeHelper to xs and ytail (the remainder of ys) in order to see.
          ((< xhead yhead)                         ; if xhead < yhead, then we do the same as above but with xhead instead of
           (cons xhead (mergeHelper xtail ys)))    ;   yhead, and xtail instead of ytail.
          (t                                       ; the only other case is that xhead == yhead. in that case they can both 
            (append (list xhead yhead)             ;   just be added to the list that's being built and mergeHelper applied
                    (mergeHelper xtail ytail)))))) ;   to the tails.

;; In Haskell you can define functions in let/where clauses and that tends to be the way to handle 
;; helper functions and I was curious if that's possible with let and lambda in lisp, but, alas, it
;; is not. I did find out that there is a function called `labels` that allows you to locally define
;; functions but I imagine nesting it like that would heavily impair readability.


;; mergeSort takes the list to be sorted, checks if the list has more than 1 element. If it has 1 or
;; 0 elements it will return the element or nil respectively. If the list has more than 1 element it
;; will be cut in half and the halves will have mergeSort applied to them until they're singlet
;; lists. Afterwards mergeSort will apply the mergeHelper function to the lists it has halved which
;; will combine them in a sorted manner. Finally it returns the original list supplied to it, but
;; sorted.
(defun mergeSort (xs) 
  "sort a list by the merge sort algorithm."
  (if (>= 1 (length xs))                     ; if length of xs <= 1 then 
        xs                                   ;   return the list supplied to mergeSort. 
                                             ; otherwise 
                                             ;   then list will be halved and have mergeSort applied to them.
        (let* ((low 0)                       ; local variables to divide lists in half. low definition is just for clarity.
               (high (length xs))            ;   high needed to find middle of the list.
               (middle (floor (/ high 2)))   ;   middle of the list is used to split the list into equal halves.
               (ls (subseq xs low middle))   ;   ls is the lower sublist
               (hs (subseq xs middle)))      ;   hs is the higher sublist
          (mergeHelper (mergeSort ls)        ; mergeHelper is applied to recursive calls of mergeSort on both halves of the 
                       (mergeSort hs)))))    ;   list because when mergeSort hits a base case, then mergeHelper will sort the
                                             ;   lists and always supply pre-sorted lists to other calls to mergeHelper lower
                                             ;   on the stack 

;; This in an example execution of mergeSort. The syntax is Haskell (which I find clearer). The ":"
;; operater works like "cons" in CL, but is infix instead of prefix.
;;
;; mergeSort [3,1,5]
;; mergeHelper (mergeSort [3]) (mergeSort [1,5])
;; mergeHelper [3] (mergeHelper (mergeSort [1]) (mergeSort [5]))
;; mergeHelper [3] (mergeHelper [1] [5])
;; mergeHelper [3] (1 : mergeHelper [] [5])
;; mergeHelper [3] [1,5]
;; 1 : mergeHelper [3] [5]
;; 1 : 3 : mergeHelper [] [5]
;; [1,3,5]





;;; Quick Sort

;; This is a recursive implementation of quick sort. It takes the list to be sorted and returns the 
;; sorted list. I've written quick sort in Haskell before and it is exactly the same as here, just
;; less parentheses and more concise. 

;; This quicksort function takes a list, uses the car of it as a pivot, and creates two sublists 
;; from the remaining elements, one smaller and one larger. Those lists have quicksort applied to 
;; them and the results are appended with the pivot in the order: smaller, pivot, larger. When the
;; function has a singlet or empty list the recursion stops and all the sublists are appended. At
;; this point, the inital list is sorted.
(defun quickSort (xs)
  "sort a list by the quick sort algorithm."
  (if (>= 1 (length xs))                                        ; if length xs <= 1 then xs is sorted, no more recursion 
      xs                                                        ;   necessary. 
                                                                ; otherwise, can't be sure and must break the list down more
      (let* ((head (car xs))                                    ; head is used to create sublists of smaller/larger values
             (tail (cdr xs))                                    ; tail is sorted into smaller/larger. somewhat optional var
             (smaller (remove-if-not #'(lambda (x) (<= x head)) ; smaller is list of values less than or equal to head.
                                     tail))                     ;   remove-if-not is "filter" in other languages.
             (larger  (remove-if-not #'(lambda (x) (>  x head)) ; larger is a list of values greather than head.
                                     tail)))                    ;
        (append (quickSort smaller)                             ; appends the sorted smaller list with the current pivot and
                (list head)                                     ;   then the sorted larger list. The smaller list and larger
                (quickSort larger)))))                          ;   list both have quickSort applied to them which break them
                                                                ;   down into smaller and larger portions until the base case
                                                                ;   is reached then the list is sorted.


;; As with mergeSort, here's an example execution:
;;
;; quickSort [3,1,5]
;; quickSort [1] ++ [3] ++ quickSort [5]
;; [1] ++ [3] ++ [5]
;; [1,3,5]
