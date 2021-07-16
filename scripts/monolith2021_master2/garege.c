#include "garege.h"

typedef enum {
  READDATA_L1,
  READDATA_L2,
  EXIT,
} STATE;

typedef struct this_st
{
  STATE state;
} this_t;

static this_t this = {
  .state = READDATA_L1
};

bool garege_do(void)
{
  switch (this.state)
  {
	case READDATA_L1:
    printf("GAREGE\n");
		this.state = READDATA_L2;
	  break;
	 
	case READDATA_L2:
    printf("GAREGE\n");
		this.state = EXIT;
	    break;
  }
  return (this.state == EXIT);
}


            // //チーム１のプログラム(コース)
            // //例：（直進のみ）
            // forward = 100;
            // turn = 0;
            // ev3_motor_steer(left_motor, right_motor, (int)forward, (int)turn);
            // this.state = PET;