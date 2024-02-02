#include "microblaze_sleep.h"
#include "platform.h"
#include "xgpio.h"
#include "xil_cache.h"
#include "xparameters.h"
#include "xuartlite.h"
#include <stdio.h>
#include <string.h>

#define PORT_IN XPAR_AXI_GPIO_0_DEVICE_ID  // XPAR_GPIO_0_DEVICE_ID
#define PORT_OUT XPAR_AXI_GPIO_0_DEVICE_ID // XPAR_GPIO_0_DEVICE_ID

// Device_ID Operaciones
#define def_SOFT_RST 0
#define def_ENABLE_MODULES 1
#define def_LOG_RUN 2
#define def_LOG_READ 3

// GLOBAL VARIABLES
XGpio GpioOutput;
XGpio GpioParameter;
XGpio GpioInput;
u32 GPO_Value;
u32 GPO_Param;
XUartLite uart_module;

// Funcion para recibir 1 byte bloqueante
// XUartLite_RecvByte((&uart_module)->RegBaseAddress)

enum COMANDOS
{
    KERNEL_SEL,     // 0
    LOAD_FRAME,     // 1
    END_FRAME,      // 2
    IS_FRAME_READY, // 3
    GET_FRAME       // 4
};

// FUNCTION PROTOTYPES
u32 create_command(enum COMANDOS comando, u16 data);
void write_command(u32 command);

int main()
{
    init_platform();
    int Status;
    XUartLite_Initialize(&uart_module, 0);

    GPO_Value = 0x00000000;
    GPO_Param = 0x00000000;

    Status = XGpio_Initialize(&GpioInput, PORT_IN);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    Status = XGpio_Initialize(&GpioOutput, PORT_OUT);
    if (Status != XST_SUCCESS)
    {
        return XST_FAILURE;
    }
    XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000);
    XGpio_SetDataDirection(&GpioInput, 1, 0xFFFFFFFF);

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ACA es donde se escribe toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    u8 a = 22;
    for (int i = 0; i < 1000; i++)
    {
        while (XUartLite_IsSending(&uart_module))
        {
        }
        XUartLite_Send(&uart_module, &a, 1);
    }

    u8 image[50][50];
    u8 pixel = 0;
    u8 is_frame_ready_to_read = 0;
    u8 uart_data[2];
    for (int i = 0; i < 50; i++)
        for (int j = 0; j < 50; j++)
            image[i][j] = pixel++;

    while (1)
    {
        for (int i = 0; i < 50; i++)
            for (int j = 0; j < 50; j++)
                write_command(create_command(LOAD_FRAME, image[i][j]));

        uart_data[0] = 1;
        while (!is_frame_ready_to_read)
        {
            write_command(create_command(IS_FRAME_READY, 0));
            is_frame_ready_to_read = XGpio_DiscreteRead(&GpioInput, 1);
            uart_data[1] = is_frame_ready_to_read;
            while (XUartLite_IsSending(&uart_module))
            {
            }
            XUartLite_Send(&uart_module, uart_data, 2);
        }

        uart_data[0] = 0;
        for (int i = 0; i < 50; i++)
            for (int j = 0; j < 50; j++)
            {
                write_command(create_command(GET_FRAME, 0));
                pixel = XGpio_DiscreteRead(&GpioInput, 1) & (0xFF);
                uart_data[1] = pixel;
                while (XUartLite_IsSending(&uart_module))
                {
                }
                XUartLite_Send(&uart_module, uart_data, 2);
            }
    }

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // FIN de toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    cleanup_platform();
    return 0;
}

u32 create_command(enum COMANDOS comando, u16 data)
{
    u32 command = 0;
    command |= (comando << 24);
    command |= data;
    return command;
}

void write_command(u32 command)
{
    command &= ~(1 << 31); // enable = 0
    XGpio_DiscreteWrite(&GpioOutput, 1, command);

    command |= (1 << 31); // enable = 1
    XGpio_DiscreteWrite(&GpioOutput, 1, command);

    command &= ~(1 << 31); // enable = 0
    XGpio_DiscreteWrite(&GpioOutput, 1, command);
}
