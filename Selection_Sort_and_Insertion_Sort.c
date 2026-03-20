/* DESCRIPTION: Pointer-based implementations of two sorting functions (sort1 is Selection sort and sort2 is Insertion sort), a function to copy the contents of one array to another (clone), and a function to print out the contents of an array
 */

// Run 2
// 20 21 30 31 35 39 40 43 45 60 62 64 70 71 74 75 76 80 82 88 
// 20 21 30 31 35 39 40 43 45 60 62 64 70 71 74 75 76 80 82 88

// Run 3
// 67 68 69 71 72 73 74 75 76 77 78 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99 
// 67 68 69 71 72 73 74 75 76 77 78 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99

#include <stdio.h>

// Pointer-based implementation of the selection sort algorithm. Takes a pointer to the beginning of an array of integers to be sorted and an integer that contains the length of the array then sorts the array in place.
void sort1 (int*, int);

// Pointer-based implementation of the insertion sort algorithm. Takes a pointer to the beginning of an array of integers to be sorted and an integer that contains the length of the array then sorts the array in place.
void sort2 (int*, int);

// Takes pointers to the beginning of two arrays of integers and an integer containing the length of the arrays. It then copies the contents of the first array into the second array.
void clone (int*, int*, int);

// Takes a pointer to an array of integers and an integer containing the length of that array and prints the elements out separated by a space
void print (int*, int);


void sort1 (int *s, int n) {
  int *ip; // first iterator
  int *jp; // second iterator
  int *pMinPosition; // stores 

  int temp; // used to swap between the values held at the memory addresses held by ip and pMinPosition


  // iterates through all array elements storing their memory location in the pointer ip, up until s + n (or the memory address of the first element of the array plus n * SIZE (where SIZE is the size of memory reserved for the type of item in the array)
  for (ip = s; ip < s + n; ip++) {
    pMinPosition = ip; // the current memory location in ip is stored in pMinPosition in order to compare the datum stored at it against all further items in the array to make sure it's smaller than all following items/sorted correctly

    // iterates through all memory locations but the first, storing their memory location in the pointer jp
    for (jp = ip + 1; jp < s + n; jp++) {
      if (*jp < *pMinPosition) {
        pMinPosition = jp; // if the value stored in jp is smaller than the one stored in pMinPosition then make pMinPosition point to the memory location stored in the pointer jp
      }
    }

    // uses a temp variable to switch the values at the locations pMinPosition and ip. ip will point at the first unsorted location in the array and pMinPosition will point either at that location or at a location further in the array that holds the smallest, unsorted datum.
    temp = *pMinPosition;
    *pMinPosition = *ip;
    *ip = temp;
  }
}

void sort2 (int *s, int n) {
  int *ip; // interator
  int *pLocation; // holds the location of the value we compare temp to/may be moving
  int temp; // holds the value of the element we're currently sorting

  for (ip = s + 1; ip < s + n; ip++) {
    temp = *ip; // store ip in temp to use for comparisons
    pLocation = ip - 1; // points to the left of the element we're sorting
    while (pLocation >= s && *pLocation > temp) { // while pLocation is in the lower bounds of the array and the datum it points to is greater than the value we're sorting (temp), continue loop
      *(pLocation + 1) = *pLocation;  // move the value that pLocation points to to the right an index
      pLocation--; // move the location that pLocation points to to the left one
    }
    *(pLocation + 1) = temp; // pLocation is no longer greater than temp, so, in order to sort, put the value in temp at the memory location after the one pointed to by pLocation.
  }
}

void clone (int *s, int *t, int n) {
  int *ip; // pointer iterator for for loop

  // assigns ip to the beginning of the array and iterates through all memory addresses, also incrementing the memory address of the second array (t)
  for (ip = s; ip < s + n; ip++, t++) {
    *t = *ip; // copies the datum at ip to the second array (t)
  }
}

void print (int *s, int n) {
  int *ip; // iterator
  for (ip = s; ip < s + n; ip++) { // iterate through all elements in the array s
    printf("%d ", *ip); // print all items in array s separated by spaces
  }

  printf("\n");
}

void main() {
  //int array1[] = {5,1,2,6,9,4,7,8,3}, array2[9];
  //int n=9;

  //int array1[] = {60, 70, 40, 45, 30, 35, 80, 75, 43, 31, 20, 88, 76, 74, 62, 71, 82, 64, 39, 21}, array2[20];
  //int n=20;

  int array1[] = {99, 98, 97, 96, 95, 94, 93, 92, 91, 89, 88, 87, 86, 85, 84, 83, 82, 81, 79, 78, 77, 76, 75, 74, 73, 72, 71, 69, 68, 67}, array2[30];
  int n=30;

  clone(array1, array2, n);
  sort1(array1, n);
  print(array1, n);
  sort2(array2, n);
  print(array2, n);
}

