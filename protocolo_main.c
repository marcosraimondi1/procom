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
  unsigned char datos;
  unsigned char cabecera; // 2 BYTES
  const int INICIO_DE_TRAMA = 0xA0;
  const int FIN_DE_TRAMA = 0x40;

  while (1) {
    read(stdin, &cabecera, 1);
    int inicio_trama = atoi(cabecera) & 0xF0;
    if (inicio_trama != INICIO_DE_TRAMA) {
      fprintf(stderr, ("INICIO DE TRAMA INCORRECTO: %s\n", cabecera));
      continue;
    }

    int size = atoi(cabecera) & 0x0F;

    char Lsize[2]; // L.size(HIGH) y L.size(LOW)
    read(stdin, &Lsize, 2);

    char device;
    read(stdin, &device, 1);

    char data[size];
    read(stdin, &data, size);

    char fin_trama;
    read(stdin, &fin_trama, 1);

    if (fin_trama != (FIN_DE_TRAMA + size)) {
      fprintf(stderr, ("FIN DE TRAMA INCORRECTO: %s\n", fin_trama));
    }
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ACA es donde se escribe toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    printf("received data: %s\n", data);
    int op_code = atoi(data[0]) & 0x03;

    switch (op_code) {
    case 1:
      // toggle
      XGpio_DiscreteWrite(&GpioOutput, 1, (u32)0x00000249);
      break;
    case 3:
      // leer
      XGpio_DiscreteWrite(&GpioOutput, 1, (u32)0x00000492);
      value = XGpio_DiscreteRead(&GpioInput, 1);
      datos = (char)(value & (0x0000000F));
      while (XUartLite_IsSending(&uart_module)) {
      }
      XUartLite_Send(&uart_module, &(datos), 1);
      break;
    default:
      // no reconocido
      sprintf(stderr, ("Unrecognized operation %d \n", op_code));
      sprintf(stderr, ("Valid Options: \n \t1: toggle\n\t3:leer\n"));
      break;
    }

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // FIN de toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  }

  cleanup_platform();
  return 0;
}
