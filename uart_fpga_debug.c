#include <stdio.h>
#include <string.h>

int main() {
  unsigned char datos;
  unsigned char cabecera[100]; // 2 BYTES
  const int INICIO_DE_TRAMA = 0xA0;
  const int FIN_DE_TRAMA = 0x40;

  while (1) {
    fread(&cabecera, 1, 10, stdin);
    printf("%s\n",cabecera);
	return 1;
	int inicio_trama = cabecera[0] & 0xF0;
    if (inicio_trama != INICIO_DE_TRAMA) {
      fprintf(stderr, "INICIO DE TRAMA INCORRECTO: %c\n", cabecera);
      continue;
    }

    int size = cabecera[0] & 0x0F;

    char Lsize[2]; // L.size(HIGH) y L.size(LOW)
    fread(&Lsize, 1, 2, stdin);

    char device;
    fread(&device, 1, 1, stdin);

    char data[size];
    fread(&data, 1, size, stdin);

    char fin_trama;
    fread(&fin_trama, 1, 1, stdin);

    if (fin_trama != (FIN_DE_TRAMA + size)) {
      fprintf(stderr, "FIN DE TRAMA INCORRECTO: %c\n", fin_trama);
    }
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // ACA es donde se escribe toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    printf("received data: %s\n", data);
    int op_code = data[0] & 0x03;

    switch (op_code) {
    case 1:
      // toggle
			printf("toggle");
      break;
    case 3:
      // leer
			printf("leer");
      break;
    default:
      // no reconocido
      fprintf(stderr, "Unrecognized operation %d \n", op_code);
      fprintf(stderr, "Valid Options: \n \t1: toggle\n\t3:leer\n");
      break;
    }

    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    // FIN de toda la funcionalidad
    //%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  }

  return 0;
}
