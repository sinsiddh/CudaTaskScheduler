#include <stdio.h>
#include <stdlib.h>
#include <cuda.h>
#include <sys/time.h>
#include "./p3.h"

__device__ uint get_smid(void) {
  uint ret;
  asm("mov.u32 %0, %smid;" : "=r"(ret) );
  return ret;
}

//Sid: Function to be called on device for addition of the elements from queue[3] to queue[103] and so on
__device__ void* calcValue(void *voidQueue) {
   if (threadIdx.x <101) {
      int sm = get_smid();
      taskQueue_t *queues = (taskQueue_t*)voidQueue;

      int size = queues[(sm*104)+1].val;
      int thread_no = queues[624].val;

      int steps = size/thread_no;
      int rem = size-(steps*thread_no);
      int i = 0;
      int start_index = (sm*104)+3;

      if (threadIdx.x < rem) {
         steps+=1;
      }
      if (threadIdx.x < size) {
         for (i = 0; i<steps; i++) {
             atomicAdd(&queues[(sm*104)+2].val, queues[start_index+(i*thread_no)+threadIdx.x].val);
             queues[start_index+(i*thread_no)+threadIdx.x].taskDone = 1;
         }
      }
      __syncthreads();
      //Sid:Check that all tasks for the SM are done
      for( i = start_index; i<=(start_index+100); i++){
         if (queues[i].taskDone = 0) {
            queues[sm*104].taskDone = 0;
            break;
         } else {
            queues[sm*104].taskDone = 1;
         }
      }
   }
}

//Sid: Schedule the tasks based on the task_done flag
__global__ void scheduler(taskQueue_t *queues) {
 //Sid: Limiting this to 101 as the array size is limited to 100 data only
 if (threadIdx.x <101) {
   /*Sid: Call the function based on the func_no: example func_no = 0 is addition of tasks/data.
    *     This can be extended to include other functionalities as well.
    */
   int sm = get_smid();
   if (queues[sm*104].func == 0 && queues[sm*104].taskDone == 0) {
      calcValue(queues);
   }
 }
}

//Sid:Add tasks to the individual SM's queues initially
int taskAdd(void *(*func) (void *), void *arg, int sm) {
  int index = sm*104;
  int task_size = ((int*)arg)[0];
  int i =0;
  //Sid: SM no.
  queue[index].val = sm;
  //Sid: func = 0 is for addition.This implementation is limited to Addition only. We can extend it to other functionalities as well
  queue[index].func = 0;
  queue[index].taskDone = 0;
  gettimeofday(&queue[index].start,NULL);
  gettimeofday(&queue[index++].end,NULL);
  //Sid: Size of Task i.e. No of Tasks to be performed
  if (task_size == 200){
     if (sm == 0 || sm == 1){
        task_size = 100;
     }else if (sm == 2 || sm == 3){
        task_size = 50;
     }else {
        task_size = 10;
     }
  }
  queue[index++].val = task_size;
  //Sid: Initialize Sum
  queue[index++].val = 0;
  //Sid: Set the array values
  for (i=0; i < task_size; i++) {
      queue[index].taskDone = 0;
      //Sid: Tasks in this implementation are addition of data from 0 to task_size -1
      queue[index++].val = i;
  }
  //Sid: Set the task done flag for all to 0
  queue[index++].val = 0;
  return SUCCESS;
}

//Sid: Check Task Done
int taskDone(int taskId) {
    return queue[taskId].taskDone;
}
//Sid:Below Code for calculating time interval Taken from Homework3 TfIDf program
long calcDiffTime(struct timeval* strtTime, struct timeval* endTime) {

return( endTime->tv_sec*1000000 + endTime->tv_usec - strtTime->tv_sec*1000000 - strtTime->tv_usec );
}

extern "C" int call_sched(int M, int N, int task) {

  int args[2];
  int wait = 0;
  args[0]=task;
  args[1]=N;
  //Sid: Device Queue
  taskQueue_t *dev_queue;
  int i = 0;
  long DiffTime;
  int count = 0;
  //Sid: Initialize task queue
  for (i = 0; i<MAX_TASK; i++) {
     queue[i].val = 0;
  }
  
  int size = MAX_TASK*(sizeof(taskQueue_t));
  cudaMalloc((void**)&dev_queue, size);
  //Sid: Add tasks to the queues
  for (i = 0; i<M; i++) {
     taskAdd(calcValue,&args, i);
  }
  
  queue[624].val = N;
  cudaMemcpyAsync(dev_queue, queue, size, cudaMemcpyHostToDevice,0);
  scheduler<<<M,N>>>( dev_queue);

  //Sid: Wait here and check that all tasks are done
  while (wait == 0) {
  //Sid: Update the local queue.
  cudaMemcpyAsync(queue, dev_queue, size, cudaMemcpyDeviceToHost,0);
     for (i = 0; i <M; i++) {
       if (taskDone(i*104) == 1) {
          gettimeofday(&queue[i*104].end, NULL);
          count+=1;
          DiffTime = calcDiffTime(&(queue[i*104].start), &(queue[i*104].end));
          printf("SM No. %d Completed!\nTime Taken From the time task is added to SM finishes task: %ld\nxxxxxxxxxxxx\n",i,DiffTime);
       }
     }
     if (count == 6) {
        wait = 1;
     } else {
        count = 0;
     }
  }
  cudaDeviceSynchronize();
  //Sid:Copy back results to host when all SM are finished
  cudaMemcpyAsync(queue, dev_queue, size, cudaMemcpyDeviceToHost,0);
  
  //Sid: Right now all SM are doing the same thing so we can just check one SMs function and print output accordingly for all SMs
  if (queue[0].func == 0) {
     if (task == 200) {
        printf("Task:Addition of Array of size 100 in SM 0&1. 50 in SM 2&3. 10 in SM 4&5! \nValues from 0 to 99|0 to 49|0 to 9\nSM: Output:\n");
     }else{
        printf("Task:Addition of Array of size %d! \nValues from 0 to %d\nSM: Output:\n",task,(task-1));
     }

     for (i=0;i<M;i++){
        printf("%d   %d \n",i,queue[(i*104)+2].val);
     }
  }
  //Sid: Cleanup
  cudaFree(dev_queue);
  return SUCCESS;
}
