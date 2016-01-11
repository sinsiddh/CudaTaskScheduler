#define SUCCESS 1
#define FAILURE 0
#define MAX_TASK 625

typedef struct taskQueue_t{
        int val;
        int taskDone;
        int func;
        struct timeval start;
        struct timeval end;
} taskQueue_t;
/*Sid: Flat array to be sent to the device.
 *Structure: array[0]:sm, array[1]:total number of tasks, array[2]:Result of tasks, 
 *           array[3-102]:data/tasks,
 *           array[103]:SM_task_done(When calculations on all the data/tasks for that SM are done)
 *and  so on till array[624] = No of Threads invoked by user*/
taskQueue_t queue[MAX_TASK];

int taskAdd(void *(*func) (void *), void *arg, int sm);
