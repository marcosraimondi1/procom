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

// USER DEFINES
#define INICIO_DE_TRAMA 0xA0
#define FIN_DE_TRAMA 0x40

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
  IDLE,    // 0
  RESET,   // 1
  EN_TX,   // 2
  EN_RX,   // 3
  PH_SEL,  // 4 -- selecciona la fase, el campo data envia la fase
  RUN_MEM, // 5 -- empieza a cargar la memoria
  RD_MEM,  // 6 -- lee la memoria, el campo data envia la posicion
  IS_FULL, // 7 -- pregunta si la memoria esta llena
  BER_S_I, // 8
  BER_S_Q, // 9
  BER_E_I, // 10
  BER_E_Q, // 11
  BER_HIGH // 12
};

// FUNCTION PROTOTYPES
u32 create_command(enum COMANDOS comando, u16 data);
void write_command(u32 command);
int read_trama(unsigned char *buffer);

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

  write_command(create_command(RESET, 1));
  write_command(create_command(RESET, 0));

  unsigned char data_from_python[1024];

  while (1)
  {

    int size;
    if ((size = read_trama(data_from_python)) == -1)
      continue;

    int op_code = data_from_python[0]; // MSByte

    int cmd_data = 0; // LSBytes
    for (int i = 1; i < size; i++)
      cmd_data |= data_from_python[i] << (8 * (size - i - 1));

    write_command(create_command(op_code, cmd_data));

    int size_to_send = 1;
    char data_to_send[8] = {0};
    u32 value;
    switch (op_code)
    {
    case IS_FULL:
      value = XGpio_DiscreteRead(&GpioInput, 1);
      size_to_send = 1;
      data_to_send[0] = value;
      break;

    case RD_MEM:
      value = XGpio_DiscreteRead(&GpioInput, 1);
      size_to_send = 2;
      data_to_send[1] = (char)(value >> 0) & 0xFF; // parte I
      data_to_send[0] = (char)(value >> 8) & 0xFF; // parte Q
      break;

    case BER_S_I:
    case BER_S_Q:
    case BER_E_Q:
    case BER_E_I:
      value = XGpio_DiscreteRead(&GpioInput, 1);
      u32 low = value;
      write_command(create_command(BER_HIGH, 0));
      value = XGpio_DiscreteRead(&GpioInput, 1);
      u32 high = value;
      size_to_send = 8;
      data_to_send[7] = (char)(low >> 0) & 0xFF;
      data_to_send[6] = (char)(low >> 8) & 0xFF;
      data_to_send[5] = (char)(low >> 16) & 0xFF;
      data_to_send[4] = (char)(low >> 24) & 0xFF;
      data_to_send[3] = (char)(high >> 0) & 0xFF;
      data_to_send[2] = (char)(high >> 8) & 0xFF;
      data_to_send[1] = (char)(high >> 16) & 0xFF;
      data_to_send[0] = (char)(high >> 24) & 0xFF;
      break;

    default: // el comando no devuelve, se envia un 0
      break;
    }

    // Envio via UART a fpga
    unsigned char trama[5 + size_to_send];
    trama[0] = (char)(INICIO_DE_TRAMA + size_to_send); // inicio de trama
    trama[1] = (char)0;                                // sizeH
    trama[2] = (char)0;                                // sizeL
    trama[3] = (char)0;                                // Device

    for (int i = 0; i < size_to_send; i++)
      trama[4 + i] = data_to_send[i];

    trama[4 + size_to_send] = (char)(FIN_DE_TRAMA + size_to_send); // fin de trama

    while (XUartLite_IsSending(&uart_module))
    {
    }

    XUartLite_Send(&uart_module, trama, 5 + size_to_send);

    // leer switches
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

u32 create_command(enum COMANDOS comando, u16 data)
{
  u32 command = 0;
  command |= (comando << 24);
  command |= data;
  return command;
}

void write_command(u32 command)
{
  command &= ~(1 << 23); // enable = 0
  XGpio_DiscreteWrite(&GpioOutput, 1, command);

  command |= (1 << 23); // enable = 1
  XGpio_DiscreteWrite(&GpioOutput, 1, command);

  command &= ~(1 << 23); // enable = 0
  XGpio_DiscreteWrite(&GpioOutput, 1, command);
}

int read_trama(unsigned char *buffer)
{
  unsigned char cabecera;
  unsigned char unused3[3]; // los tres siguientes bytes no se usan
  unsigned char end;

  // TRAMA:
  //        	- Byte<1> 			: INICIO DE TRAMA = 0xA0 + size
  //        (4bits)
  //        	- Byte<2:4>			: no se usan (sizeH, sizeL,
  //        Device)
  //        	- Byte<5:5+size> 	: data
  //        	- Byte<Size+1>		: FIN DE TRAMA = 0x40 + size

  read(stdin, &cabecera, 1);

  if ((cabecera & 0xF0) != INICIO_DE_TRAMA)
    return -1; // no es el inicio de trama correcto

  int size = cabecera & 0x0F; // data size

  read(stdin, unused3, 3);

  unsigned char data[size];
  read(stdin, data, size);

  read(stdin, &end, 1);

  if (end != (FIN_DE_TRAMA + size))
    return -1; // no es el fin de trama correcto

  // load data to buffer
  for (int i = 0; i < size; i++)
    buffer[i] = data[i];

  return size;
}
