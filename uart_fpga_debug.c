#include <stdio.h>
#include <string.h>

int main() {
	// b'\xa4\x00\x00\x00\x13\xff\xff\xffD'
	// b'\xa4\x00\x00\x00\x11\xff\xff\x00D' ejemplo de trama
  char datos;
  char cabecera[20]; 
  char aux[20];

	const char INICIO_DE_TRAMA[6] = "b'\xa4";
  const char FIN_DE_TRAMA = 0x40;

	// obtengo primer byte de trama
  fread(cabecera, 1, 6, stdin);
  printf("%s\n", cabecera);
	
  if (!strncmp(cabecera, INICIO_DE_TRAMA, 6))
    printf("ERROR DE INICIO DE TRAMA");
 
	// data size
	
	int size = atoi(fread()); 
	
	return 1;
}
