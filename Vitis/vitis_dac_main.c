#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

// Reset	2621441
// Power up	2097155
// Ref		3670017
// Gain 2	131072
// LDAC		3145731


// Data		1572864 + x

// Reset Data	2621440
// 30 : -9.985
// 65510 : 9.982
// a:0.000304932 b:-9.99414796
// 0.000304932 * x - 9.99414796 = V


int main()
{
	int data;
	int onoff;
	float a;

	Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 2621441);
	usleep(100000);
	Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 2097155);
	usleep(100000);
	Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 3670017);
	usleep(100000);
	Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 131072);
	usleep(100000);
	Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 3145731);
	usleep(100000);

	while(1)
	{/*
		printf("On/Off? 1 = off\n");
		scanf("%d", &onoff);

		if (onoff == 0)
			printf("On\n");

		else
			printf("Off\n");

		Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR) + 4, onoff);
*/
		printf("data?\n");
		scanf("%d", &data);

		Xil_Out32((XPAR_TOP_DAC_TEST_0_BASEADDR), 1572864 + data);

		a = ((float)data * 0.000304932) - 9.99414796;

		printf("%f\n", a);

		usleep(10000);
	}

	return 0;
}
