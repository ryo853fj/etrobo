#include "pet.h"

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

bool pet_do(void)
{
  switch (this.state)
  {
	case READDATA_L1:
    printf("PET\n");
		this.state = READDATA_L2;
	    break;
	 
	case READDATA_L2:
    printf("PET1\n");
		this.state = EXIT;
	    break;
  }
  return (this.state == EXIT);
}
