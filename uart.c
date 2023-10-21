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
    IDLE     , // 0
    RESET    , // 1
    EN_TX    , // 2
    EN_RX    , // 3
    PH_SEL   ,
    RUN_MEM  ,
    RD_MEM   ,
    IS_FULL  ,
    BER_S_I  ,
    BER_S_Q  ,
    BER_E_I  ,
    BER_E_Q  ,
    BER_HIGH ,
  };

u32 create_command(enum COMANDOS comando, u16 data)
{
  u32 command = 0;
  command |= (comando << 24);
  command |= data;
  return command;
}

void write_command(u32 command)
{ 
    command &= ~(1<<23);  // enable = 0
    XGpio_DiscreteWrite(&GpioOutput, 1, command);
    
    command |= (1<<23);   // enable = 1
    XGpio_DiscreteWrite(&GpioOutput, 1, command);
    
    command &= ~(1<<23);  // enable = 0
    XGpio_DiscreteWrite(&GpioOutput, 1, command);
}

int main() {
  init_platform();
  int Status;
  XUartLite_Initialize(&uart_module, 0);

  GPO_Value = 0x00000000;
  GPO_Param = 0x00000000;

  Status = XGpio_Initialize(&GpioInput, PORT_IN);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }
  Status = XGpio_Initialize(&GpioOutput, PORT_OUT);
  if (Status != XST_SUCCESS) {
    return XST_FAILURE;
  }
  XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000);
  XGpio_SetDataDirection(&GpioInput, 1, 0xFFFFFFFF);

  write_command(create_command(RESET, 1));
  write_command(create_command(RESET, 0));

  // trama bytes
  unsigned char cabecera;
  unsigned char unused3[3]; // los tres siguientes bytes no se usan
  unsigned char end;

  const int INICIO_DE_TRAMA = 0xA0;
  const int FIN_DE_TRAMA    = 0x40;
  

  while (1) {

    // TRAMA:
    //        	- Byte<1> 			: INICIO DE TRAMA = 0xA0 + size
    //        (4bits)
    //        	- Byte<2:4>			: no se usan (sizeH, sizeL,
    //        Device)
    //        	- Byte<5:5+size> 	: data
    //        	- Byte<Size+1>		: FIN DE TRAMA = 0x40 + size

    read(stdin, &cabecera, 1);

    if ((cabecera & 0xF0) != INICIO_DE_TRAMA)
      continue; // no es el inicio de trama correcto

    int size = cabecera & 0x0F; // data size

    read(stdin, unused3, 3);

    unsigned char data[size];
    read(stdin, data, size);

    read(stdin, &end, 1);

    if (end != (FIN_DE_TRAMA + size))
      continue; // no es el fin de trama correcto

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ACA es donde se escribe toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    int op_code = data[0]; // MSByte

    int cmd_data = 0; // LSBytes
    for (int i=1; i<size; i++)
        cmd_data |= data[i] << (8*(size-i-1));

    write_command(create_command(op_code, cmd_data));

    //Envio via UART a fpga
    unsigned char trama[6];
    int size_to_send = 1;
    trama[0] = (char)(INICIO_DE_TRAMA + size_to_send); // inicio de trama
    trama[1] = (char)0;          // sizeH
    trama[2] = (char)0;          // sizeL
    trama[3] = (char)0;          // Device
    trama[4] = (char)1;          // data
    trama[5] = (char)(FIN_DE_TRAMA + size_to_send); // fin de trama
    
    while (XUartLite_IsSending(&uart_module)) {}
    XUartLite_Send(&uart_module, trama, 6);



    //   // leer switches
    //   led_value = 0;
    //   XGpio_DiscreteWrite(&GpioOutput, 1, led_value);
    //   value = XGpio_DiscreteRead(&GpioInput, 1);
    //   datos = (char)(value & (0x0000000F));
   

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // FIN de toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  }

  cleanup_platform();
  return 0;
}

