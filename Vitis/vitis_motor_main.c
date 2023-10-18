// XPAR_TOP_MOTOR_0_BASEADDR

#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

int main()
{
	int step;

	Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 12), 1000000);

	Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 20), 0);

	Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 28), 1);

	Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 24), 1);

	while(1)
	{
		Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 16), 0);

		usleep(1000);

		printf("step? : \n");
		scanf("%d", &step);

		Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR) + 8, step);

		usleep(1000);

		Xil_Out32((XPAR_TOP_MOTOR_0_BASEADDR + 16), 1);

		usleep(1000000);
	}

	return 0;
}
