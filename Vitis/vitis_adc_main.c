#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "sleep.h"

int main()
{
	int i;
	int b;
	float a;
	int adc_data;

	Xil_Out32((XPAR_TOP_ADC_TEST_V2_0_BASEADDR + 8), 240);
	Xil_Out32((XPAR_TOP_ADC_TEST_V2_0_BASEADDR + 12), 1000);
	Xil_Out32((XPAR_TOP_ADC_TEST_V2_1_BASEADDR + 8), 240);
	Xil_Out32((XPAR_TOP_ADC_TEST_V2_1_BASEADDR + 12), 1000);

	while(1)
	{
		scanf("%d\n", &b);
//		printf("%d\n", b);

		for (i = 0; i < 1000; i++)
		{
			Xil_Out32((XPAR_TOP_ADC_TEST_V2_0_BASEADDR + 20), (u32)i);

			usleep(100);

			adc_data = Xil_In32((XPAR_TOP_ADC_TEST_V2_0_BASEADDR + 16));

			if (adc_data > 32768)
			{
				a = ((65535 - adc_data + 1) * 0.0003814) + 0.000732;
				printf("-%f  ", a);
			}

			else if (adc_data < 32768)
			{
				a = (adc_data * 0.0003814) + 0.000732;
				printf("%f  ", a);
			}

			else
				printf("0  ");

			if (i%4 == 3)
				printf("\n");

			usleep(100);

		}
		printf("\n");
		printf("///////////////////////\n");


		for (i = 0; i < 1000; i++)
		{
			Xil_Out32((XPAR_TOP_ADC_TEST_V2_1_BASEADDR + 20), (u32)i);

			usleep(100);

			adc_data = Xil_In32((XPAR_TOP_ADC_TEST_V2_1_BASEADDR + 16));

			if (adc_data > 32768)
			{
				a = ((65535 - adc_data + 1) * 0.0003814) + 0.000732;
				printf("-%f  ", a);
			}

			else if (adc_data < 32768)
			{
				a = (adc_data * 0.0003814) + 0.000732;
				printf("%f  ", a);
			}

			else
				printf("0  ");

			if (i%4 == 3)
				printf("\n");

			usleep(100);

		}
		printf("\n");
		printf("///////////////////////\n");




		/*
		adc_data = Xil_In32((XPAR_TOP_ADC_TEST_V2_0_BASEADDR));

		if (adc_data > 32768)
		{
			a = ((65535 - adc_data + 1) * 0.0003814) + 0.000732;
			printf("-%f\n", a);
		}

		else if (adc_data < 32768)
		{
			a = (adc_data * 0.0003814) + 0.000732;
			printf("%f\n", a);
		}

		else
			printf("0\n");
*/
		usleep(1000000);

	}

	return 0;
}
