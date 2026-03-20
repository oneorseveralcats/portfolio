/* DESCRIPTION: Assembly program that iterates through the even numbers between 22 to 100 (inclusive), it finds two numbers that add up to that number that are prime. The first number will be the smallest prime number that can add up to it with another prime number. After finding the two numbers the program exits the assembly block, prints them and the number they add up to in c, and then enters another assembly block that continues the program at the next loop iteration.
*/

// Output
//
// 11 + 11 = 22
// 11 + 13 = 24
// 13 + 13 = 26
// 11 + 17 = 28
// 11 + 19 = 30
// 13 + 19 = 32
// 11 + 23 = 34
// 13 + 23 = 36
// 19 + 19 = 38
// 11 + 29 = 40
// 11 + 31 = 42
// 13 + 31 = 44
// 17 + 29 = 46
// 11 + 37 = 48
// 13 + 37 = 50
// 11 + 41 = 52
// 11 + 43 = 54
// 13 + 43 = 56
// 11 + 47 = 58
// 13 + 47 = 60
// 19 + 43 = 62
// 11 + 53 = 64
// 13 + 53 = 66
// 31 + 37 = 68
// 11 + 59 = 70
// 11 + 61 = 72
// 13 + 61 = 74
// 17 + 59 = 76
// 11 + 67 = 78
// 13 + 67 = 80
// 11 + 71 = 82
// 11 + 73 = 84
// 13 + 73 = 86
// 17 + 71 = 88
// 11 + 79 = 90
// 13 + 79 = 92
// 11 + 83 = 94
// 13 + 83 = 96
// 19 + 79 = 98
// 11 + 89 = 100

#define TRUE 1
#define FALSE 0

#include <stdio.h>

void main() {
  int is1Prime, is2Prime; // flags used to check if the selected numbers were prime in the C version of the program
  int i, j, k;            // iterators used in the C version of the program
                         
  int number0;          // this variable stores the even number that number1 and number2 add up to
  int number1, number2; // stores the numbers that are being tested for prime
  int divisor;          // holds the value that's being divided by either number1/number2 to see if they're prime


  // important labels explained:
  //
  // outer - this is the outer loop that iterates through from 22 to 100. It uses ebx as it's iterator and the value is updated by 2 every loop (because even numbers). The value of ebx is stored in number0 and that variable is used through out the program to derive number2 from and to print to the screen.
  //
  // inner - this is an inner loop that starts at 11 (the first prime number greater than 7) and iterates upward until it reaches the number. If for whatever reason it can't find two prime numbers that add together to be the target number (which is literally impossible), it will jump to the next iteration of the outer loop. The body of the loop assigns the variables number1 and number2 for each iteration and those are used in the sections prime1 and prime2 to test if they're prime
  //
  // prime1 - a loop that compares number1 against all values between (number1-1) and 1 (exclusive) by way of comparing the remainder of dividing number1 to the decreasing iterator value. If there's ever no remainder for the division, the program jumps to the next inner loop cycle because if number1 isn't prime then whether number2 is prime doesn't matter. If number1 doesn't cleanly divide before the iterator decreases to the value 1 (which is divisible by all positive integers), then the program branches to isprime1 which sets the inital conditions for the prime2 loop to run.
  //
  // prime2 - essentially a copy of prime1, but uses number2 instead of number1. If number2 isn't prime then jumps to the inner loop to try the next set of numbers. If number2 is prime then jumps to label isprime2. 
  //
  // isprime2 - if number2 is prime, then number1 is prime as well so both numbers are printed along with the number they add up to. After the numbers are printed, the program jumps back to the outer loop which starts the whole process again but with the next even number.
 
  __asm {
              mov ebx, 22       // iterator ebx value is 22
    outer:    cmp ebx, 100      // is ebx > 100?
              jg  xout          // if so, program over
              mov number0, ebx  // store value in ebx in number0 to be used to calculate number2 and print later
              add ebx, 2        // increment ebx by 2 because only testing even numbers

              mov ecx, 11       // iterator ecx value is set to 11. 11 is the next prime after 7
    inner:    cmp ecx, number0  // is ecx >= number0?
              jge outer         // If so, start jump to the outer loop, starting the next iteration. This branch should never be used. It would imply that the program couldn't find two prime numbers that add up to number0 which is impossible, well, unless number0 < 13
              mov number1, ecx  // the value in ecx is stored in number1 to be used in the prime1 loop. I use a variable because I have to iterate ecx as well but need the current value.
              mov eax, number0  // moves number0 temporarily to a register because you can't move from variable to variable
              sub eax, ecx      // eax (number0) - number1 = eax (number2)
              mov number2, eax  // moves the value from eax into number2 for safe keeping
              add ecx, 2        // increments the iterator for inner by 2. It's by 2 because even numbers can't be prime so no point in checking them.

              mov edx, number1  // iterator ebx is set to the number that's being checked if prime.
              dec edx           // decremented by 1 because number1 is divisible by itself and would cause the loop to see all numbers as non-prime
    prime1:   cmp edx, 1        // is edx =< 1?
              jle isprime1      // if so, number1 is prime so jump to isprime1 where number2 is checked.
              mov eax, number1  // moves number1 into the accumulator because div uses eax as the dividend
              mov divisor, edx  // stores edx in divisor to be used in the div instruction. edx is used for div and also as the iterator so it's important to keep the value for both the divisor and the loop itself.
              mov edx, 0        // clear edx before division
              div divisor       // do division
              cmp edx, 0        // the remainder of the division is stored in edx, this compares it against 0. If a division has a remainder of 0 then the divisor is a factor of the dividend and the dividend is not prime
              jne cond1f        // if there's a remainder, jump to cond1f
              jmp inner         // if not, then jump to the next iteration of the inner loop
    cond1f:   mov edx, divisor  // move the divisor back into edx in preparation for the next iteration of the loop
              dec edx           // decrease edx by 1
              jmp prime1        // jump to the statement that compares edx to 1 again

    isprime1: mov edx, number2  // edx is the iterator for prime2 as well. move number2 into it
              dec edx           // decrease edx by 1 because number2 % edx (number2) = 0
    prime2:   cmp edx, 1        // edx < 1?
              jle isprime2      // if so, number2 is prime jump to isprime2 which prints out the numbers
              mov eax, number2  // eax is where the dividend is stored
              mov divisor, edx  // edx is used in div, so move the value to divisor
              mov edx, 0        // clear edx before division
              div divisor       // do division. number2 % divisor = ?
              cmp edx, 0        // is there remainder?
              jne cond2f        // if so, jump to cond2f
              jmp inner         // if no remainder, then number2 is not prime. Start next iteration of the inner loop
    cond2f:   mov edx, divisor  // move the divisor/value being interated back into edx
              dec edx           // decrease it by one for next loop iteration
              jmp prime2        // jump to beginning of the loop

    isprime2:                   // if number2 is prime, jump here.
    }

   printf("%d + %d = %d\n", number1, number2, number0); // print out the two prime numbers and the number they add up to
 
  __asm {
              jmp outer // jump to the outer loop which moves on to the next even number.
 
    xout:               // program over
  }

  // in C:
  //
  // for (i = 22; i <= 100; i += 2) {
  //   for (j = 11; j < i; j += 2) {
  //     is1Prime = TRUE;
  //     is2Prime = TRUE;

  //     number1 = j;
  //     number2 = i-j;

  //     for (k = number1-1; k > 1; k--) {
  //       if (number1 % k == 0) {
  //         is1Prime = FALSE;
  //         break;
  //       }
  //     }

  //     for (k = number2-1; k > 1; k--) {
  //       if (number2 % k == 0) {
  //         is2Prime = FALSE;
  //         break;
  //       }
  //     }

  //     if (is1Prime && is2Prime) {
  //       printf("%d + %d = %d\n", number1, number2, i);
  //       break;
  //     }
  //   }
  // }
}
