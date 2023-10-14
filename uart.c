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

  u32 value;
  u32 led_value = 0;

  unsigned char datos; // respuesta

  // trama bytes
  unsigned char cabecera;
  unsigned char unused3[3]; // los tres siguientes bytes no se usan
  unsigned char end;

  while (1) {
    // TRAMA:
    //        	- Byte<1> 			: INICIO DE TRAMA = 0xA0 + size
    //        (4bits)
    //        	- Byte<2:4>			: no se usan (sizeH, sizeL,
    //        Device)
    //        	- Byte<5:5+size> 	: data
    //        	- Byte<Size+1>		: FIN DE TRAMA = 0x40 + size

    read(stdin, &cabecera, 1);

    if ((cabecera & 0xF0) != 0xA0)
      continue; // no es el inicio de trama correcto

    int size = cabecera & 0x0F; // data size

    read(stdin, unused3, 3);

    unsigned char data[size];
    read(stdin, data, size);

    read(stdin, &end, 1);

    if (end != (0x40 + size))
      continue; // no es el fin de trama correcto

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ACA es donde se escribe toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    int op_code = data[0];

    if (op_code == 3) {
      // leer switches
      led_value = 0;
      XGpio_DiscreteWrite(&GpioOutput, 1, led_value);
      value = XGpio_DiscreteRead(&GpioInput, 1);
      datos = (char)(value & (0x0000000F));
      unsigned char trama[6];
      trama[0] = (char)(0xA0 + 1); // inicio de trama
      trama[1] = (char)0;          // sizeH
      trama[2] = (char)0;          // sizeL
      trama[3] = (char)0;          // Device
      trama[4] = datos;            // data
      trama[5] = (char)(0x40 + 1); // fin de trama

      while (XUartLite_IsSending(&uart_module)) {
      }
      XUartLite_Send(&uart_module, trama, 6);
    }

    if (op_code == 1) {

      int led = data[1] % 4;
      int red = data[2] % 2;
      int green = data[3] % 2;
      int blue = data[4] % 2;

      int rgb = (red << 2) | (green << 1) | blue;

      int new_value = rgb << (3 * led);

      led_value |= new_value; // pone los 1s

      led_value &= (new_value | (~((1 << (3 * (led + 1))) - 1)) |
                    ((1 << (3 * led)) - 1)); // pone los 0s

      XGpio_DiscreteWrite(&GpioOutput, 1, led_value);
    }

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // FIN de toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  }

  cleanup_platform();
  return 0;
}
