/*
 * Example of using AXI-Stream instructions efficiently in MicroBlaze.
 *
 * See "Pipeline Architecture - Avoiding Data Hazards" in Chapter 2 of the
 * MicroBlaze Processor Reference Guide (UG984) for details.
 */
#include <stdio.h>
#include <fsl.h>

#define BUFFER_SIZE 13

/*
 * Write 1 32-bit word blocking, will block program until it writes the value (slave sends TREADY high).
 */
static void inline write_axis(volatile unsigned int a)
{
    register int a0;
    a0  = a;
    putfslx(a0,  0, FSL_DEFAULT);
}

/*
 * Read 1 32-bit word blocking, will block program until data is available to read (master sends TVALID high).
 */
static void inline read_axis(volatile unsigned int *a)
{
    register int a0;
    getfslx(a0,  0, FSL_DEFAULT);
    a[0]  = a0;
}

int main()
{
    volatile unsigned int outbuffer[BUFFER_SIZE] = {
    	72, 101, 108, 108, 111, 44, 32, 87, 111, 114, 108, 100, 33
    }; // Hello World! in ascii

    volatile unsigned int inbuffer[BUFFER_SIZE];

    char a[128] = "A";

    print("starting ....\n");

    /* Perform transfers */
    int count = 0;
    while (count < BUFFER_SIZE) {
        write_axis(outbuffer[count]);
        read_axis(inbuffer);
        a[count] = inbuffer[0];
        count++;
    }
    a[count] = '\n';

    print(a);
    print("program ended \n");

    return 0;
}
