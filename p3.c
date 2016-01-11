#include <stdio.h>
#include <stdlib.h>
#include "./p3.h"

int main(int argc, char *argv[]){
  int task[4] = {100,50,10,200};
  if (argc != 4){
     printf("Exiting. Block, Thread or Size of task not provided.\n");
     printf("Please see README for instructions to run the program. \nSize of Task: 1-  Large : 2- Medium : 3- Small 4- Mixed\n");
     exit(1);
  }

  int N = atoi(argv[1]);
  int M = atoi(argv[2]);
  int input = atoi(argv[3]);
  if (N!=6) {
     printf("Exiting. Value of Blocks should be equal to 6 so that all 6 SMs have tasks to perform \n");
     exit(1);
  }
  
  if(input>4 || input<1) {
    printf("Exiting.Incorrect Input.\n");
    printf("Suitable Values Are: 1 for Large. 2 For Medium. 3 For Small. 4 for Mixed Inputs \n");
    exit(1);
  } 
  int ret = call_sched(N, M, task[input-1]);
  if (ret != 1) {
     printf("CUDA call failed\n");
  }
  return 0;
}
