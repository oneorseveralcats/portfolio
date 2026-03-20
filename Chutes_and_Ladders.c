/* DESCRIPTION: Implementation of the game chutes and ladders in 6 functions. Both players start at the beginning of the board and move a random amount between 1-6. If a player lands on an 'F' space the program finds the closest 'H' space in front of them, moves them to it, and removes it. If there's no 'H' space in front of them the player stays in place. If the player lands on a 'B' space they're moved to the closest 'H' space behind them or, if there are none, the beginning of the board. If a player lands on a letter within the range "a-m" they've landed on a chute that'll take them back a certain distance, "o-z" is a ladder that'll take them forward a certain distance. The first player to get to the end of the board (or if both do in the same turn, the furthest) wins. The game has a console output that keeps track of the events in the game and also a text log that contains all board states at the end of both players turns.
 *
 * The program is implemented in 6 functions (explained in detail below):
 *              - main
 *              - printBoard
 *              - move
 *              - findHaven
 *              - chuteLadder
 *              - isCollision
 */

#define SIZE 100

#define TRUE  1
#define FALSE 0

#include <stdio.h>
#include <stdlib.h>
#include <time.h>

// takes pointers to both players, a pointer to the board, and an output file. Outputs the board state to the output file, replacing the tiles where player 1 and 2 are with 1 and 2, respectively.
void printBoard(char*, char*, char*, FILE*);

// takes pointers to both players, an integer to tell whose turn it is, and a pointer to the board. Generates a random number that the current player moves, checks to see if there's a collision with the other player, then checks to see if the current player landed on a 'F'/'B' space or a chute/ladder. If so, it calls the appropriate functions (findHaven or chuteLadder)
char* move(char*, char*, int, char*);

// takes the current player and the board. Checks to see what space the player landed on ('B' or 'F'), and based on that either searches Forward ('F') or Backwards ('B') for the closest haven. The function returns the clostest haven if there is one. If not, and searching backwards, it returns &board[0]. If not, and searching forwards, it returns the current position of the player.
char* findHaven(char*, char*);

// takes the current player and moves them backwards or forewards a certain amount depending on the value of the chute or ladder they landed on.
char* chuteLadder(char*);

// takes the current player, and the other player, and the board. Checks to see if they're on the same space and not on the first space of the board. If so, returns TRUE, otherwise returns FALSE.
int isCollision(char*, char*, char*);


void printBoard(char* board, char* p1, char* p2, FILE* fileOut) {
  char *ip;

  // iterates through the board until the null character
  for (ip = board; *ip != '\0'; ip++) {
    if (ip != p1 && ip != p2) { // if p1 and p2 aren't pointing to a memory location, just output the character
      putc (*ip, fileOut);
    } else if (ip == p1) { // if the iterator is pointing to the same location as p1 then output '1' instead of whatever space is on the board
      putc ('1', fileOut);
    } else {
      putc ('2', fileOut); // if the iterator is pointing at the same location as p2, output 2
    }
  }
  putc ('\n', fileOut); // linebreak

}

char* move(char* p1, char* p2, int pNum, char* board) {
  int startingLocation, // stores the inital location of the player for output
      randomAmount;  // stores the amount the player moves for output
  char *player, // player currently moving
       *enemy;  // their immortal foe

  // assigns alias pointers based on which player is moving
  if (pNum == 1) {
    player = p1;
    enemy = p2;
  } else {
    player = p2;
    enemy = p1;
  }

  randomAmount = rand() % 6 + 1; // random number between 1-6
  startingLocation = player - board; // starting board position

  player = player + randomAmount; // player position prior to collision and F/B and chute/ladder calculations
                          
  // prints basic output about which player is moving, how many spaces, and from where to where
  printf("Player %d moves %d from %d to %d", pNum, randomAmount, startingLocation, player - board);

  // checks if there's a collision and, if so, moves the current player back 1 and prints collision output
  if (isCollision(player, enemy, board)) {
    player--;
    printf(" and collides with the other player, moving back 1 to %d", player - board);
  }

  // checks if player is on a 'B' or 'F' space, and then calls findHaven to find the closest haven and move to it, or move to the beginning (B), or do nothing (F).
  if (*player == 'B' || * player == 'F') {
     player = findHaven(player, board);
  } else if (*player >= 'a' && *player <= 'm') { // checks to see if the player is on a chute, if so calls chuteLadder to calculate where the players taken and prints relevant output
      player = chuteLadder(player);
      printf(" and lands on a chute and slides back to %d", player - board);
  } else if (*player >= 'o' && *player <= 'z') { // checks to see if the player is on a ladder, if so calls chuteLadder to calculate where the players taken and prints relevant output
      player = chuteLadder(player);
      printf(" and lands on a ladder and climbs up to %d", player - board);
  }

  // checks to see if there's a collision after all other calculations have been done. If so, moves the current player back one and prints relevant output
  if (isCollision(player, enemy, board)) {
    player--;
    printf(" and collides with the other player, moving back 1 to %d", player - board);
  }

  printf("\n");

  return player; // returns the final position of the player for this turn. I forgot this and was troubleshooting for like half an hour
}

int isCollision(char* player, char* enemy, char* board) {

  // if player and enemy are on the same tile but not at &board[0], return TRUE, otherwise return FALSE
  if (player == enemy && player != board) {
    return TRUE;
  }

  return FALSE;
}

char* findHaven(char* player, char* board) {
  char *ip; // iterator

  // if player is on B, searches backwards for the closest Haven
  if (*player == 'B') {
      printf(" and lands on a B");
      for (ip = player; ip > board; ip--) { // uses pointers to iterate backwards from the space the players on to the beginning of the board in search of a memory location that holds the character 'H'
        if (*ip == 'H') {
          printf(" and moves backwards to %d", ip - board);
          *ip = '*'; // replace used 'H' with '*'
          return ip; // return board location of first 'H' found
        }
      }
      printf(" and moves backwards to 0"); // if no Haven is found return the the first board position (%board[0])
      return board;
  } else if (*player == 'F') { // if the current memory location holds the character 'F' then search forward until the end of the board for an 'H'
      printf(" and lands on a F");
      for (ip = player; ip < board + SIZE; ip++) {
        if (*ip == 'H') {
          printf(" and moves forwards to %d", ip - board);
          *ip = '*'; // replaces used 'H' with '*'
          return ip;
        }
      }
      printf(" and stays in place", ip - board); // if no 'H' is found from the position of the player to the end of the board, then stay in place (return the current position of the player) and print the relevant output.
      return player;
  }

}

char* chuteLadder(char* player) {
  char* pTemp = player + (int)(*player-'n');
  *player = '-'; // used chutes/ladders become '-'
  return pTemp; // calculates where the player should end up and returns that location
}

void main() {
  char board[100]="  mHk wH l B He Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB ";

  char *p1 = board,
       *p2 = board;

  FILE *fileOut;

  fileOut = fopen ("out.txt", "w");
  srand(time(NULL)); // Seed random number generator

  printBoard(board, p1, p2, fileOut); // print initial state

  // loop until either p1 or p2 is at or past the end of the board
  while(p1 <= board + SIZE && p2 <= board + SIZE) {
    p1 = move(p1, p2, 1, board);
    p2 = move(p1, p2, 2, board);
    printBoard(board, p1, p2, fileOut);
  }

  // if the while loop ends, one player is at/past the end of the board so one wins. The one with more points is the one that wins
  printf("\n");
  if (p1>p2) {
    printf("Player 1 wins!\n");
  } else {
    printf("Player 2 wins!\n");
  }

  fclose(fileOut);
}


// Output 
//
// Player 1 moves 1 from 0 to 1
// Player 2 moves 4 from 0 to 4 and lands on a chute and slides back to 1 and collides with the other player, moving back 1 to 0
// Player 1 moves 1 from 1 to 2 and lands on a chute and slides back to 1
// Player 2 moves 1 from 0 to 1 and collides with the other player, moving back 1 to 0
// Player 1 moves 4 from 1 to 5
// Player 2 moves 2 from 0 to 2
// Player 1 moves 1 from 5 to 6 and lands on a ladder and climbs up to 15
// Player 2 moves 5 from 2 to 7
// Player 1 moves 5 from 15 to 20 and lands on a ladder and climbs up to 22
// Player 2 moves 6 from 7 to 13
// Player 1 moves 1 from 22 to 23
// Player 2 moves 6 from 13 to 19
// Player 1 moves 1 from 23 to 24
// Player 2 moves 3 from 19 to 22
// Player 1 moves 2 from 24 to 26 and lands on a B and moves backwards to 22 and collides with the other player, moving back 1 to 21
// Player 2 moves 5 from 22 to 27 and lands on a ladder and climbs up to 38
// Player 1 moves 2 from 21 to 23
// Player 2 moves 5 from 38 to 43 and lands on a B and moves backwards to 41
// Player 1 moves 3 from 23 to 26 and lands on a B and moves backwards to 13
// Player 2 moves 6 from 41 to 47
// Player 1 moves 5 from 13 to 18 and lands on a ladder and climbs up to 21
// Player 2 moves 1 from 47 to 48 and lands on a chute and slides back to 44
// Player 1 moves 5 from 21 to 26 and lands on a B and moves backwards to 7
// Player 2 moves 4 from 44 to 48
// Player 1 moves 6 from 7 to 13
// Player 2 moves 1 from 48 to 49
// Player 1 moves 2 from 13 to 15
// Player 2 moves 1 from 49 to 50
// Player 1 moves 1 from 15 to 16 and lands on a F and moves forwards to 28
// Player 2 moves 4 from 50 to 54
// Player 1 moves 5 from 28 to 33
// Player 2 moves 5 from 54 to 59 and lands on a chute and slides back to 49
// Player 1 moves 5 from 33 to 38 and lands on a chute and slides back to 34
// Player 2 moves 3 from 49 to 52
// Player 1 moves 5 from 34 to 39 and lands on a ladder and climbs up to 43
// Player 2 moves 2 from 52 to 54
// Player 1 moves 4 from 43 to 47
// Player 2 moves 3 from 54 to 57
// Player 1 moves 6 from 47 to 53 and lands on a F and moves forwards to 62
// Player 2 moves 1 from 57 to 58 and lands on a chute and slides back to 51
// Player 1 moves 1 from 62 to 63
// Player 2 moves 6 from 51 to 57
// Player 1 moves 6 from 63 to 69
// Player 2 moves 1 from 57 to 58
// Player 1 moves 6 from 69 to 75 and lands on a F and moves forwards to 79
// Player 2 moves 6 from 58 to 64 and lands on a ladder and climbs up to 66
// Player 1 moves 3 from 79 to 82 and lands on a chute and slides back to 81
// Player 2 moves 1 from 66 to 67
// Player 1 moves 4 from 81 to 85 and lands on a B and moves backwards to 69
// Player 2 moves 5 from 67 to 72
// Player 1 moves 6 from 69 to 75 and lands on a F and moves forwards to 87
// Player 2 moves 2 from 72 to 74 and lands on a B and moves backwards to 50
// Player 1 moves 3 from 87 to 90 and lands on a F and moves forwards to 94
// Player 2 moves 3 from 50 to 53 and lands on a F and moves forwards to 89
// Player 1 moves 4 from 94 to 98
// Player 2 moves 1 from 89 to 90 and lands on a F and stays in place
// Player 1 moves 3 from 98 to 101
// Player 2 moves 3 from 90 to 93 and lands on a ladder and climbs up to 94
// 
// Player 1 wins!


// out.txt
//
// 1 mHk wH l B He Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
// 21mH- wH l B He Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
// 21-H- wH l B He Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   2H-1wH l B He Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -2 l B He1Flq p H  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B 2e Flq - 1  hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B He Flq2- H1 hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B He Flq - 2 1hByHlho H B  jr HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B He Flq -1*  hB-Hlho H B  2r HFB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B He Flq - *1 hB-Hlho H B  jr 2FB ir j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B 1e Flq - *  hB-Hlho H B  jr *FB ir2j H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -H l B *e Fl- -1*  hB-Hlho H B  jr *FB2ir - H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -1 l B *e Fl- - *  hB-Hlho H B  jr *FB ir 2 H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B 1e Fl- - *  hB-Hlho H B  jr *FB ir -2H  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e1Fl- - *  hB-Hlho H B  jr *FB ir - 2  F ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-1lho H B  jr *FB ir - H  F2ku gd  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho 1 B  jr *FB ir -2H  F ku g-  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H1B  -r *FB ir - H 2F ku g-  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *F1 ir - H  F2ku g-  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir1- H  F ku2g-  H pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H2 F ku --  1 pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H  F ku2--  *1pjB mH x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H  F ku 2-  * pjB m1 x  BF i H  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H  F ku --  * -j2 mH x  BF i 1  m oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H  F ku --  * -jB2mH x  BF i * 1- oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - H  F ku --  * -jB m1 x2 BF i *  - oB HlHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - 2  F ku --  * -jB m* x  BF i *  - oB 1lHFBhoH BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - *  F ku --  * -jB m* x  BF i *  - oB *l2FBho1 BB 
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - *  F ku --  * -jB m* x  BF i *  - oB *l*2Bho* BB1
//   -H- -* l B *e Fl- - *  hB-*lho H B  -- *FB ir - *  F ku --  * -jB m* x  BF i *  - oB *l*FBh-2 BB 

