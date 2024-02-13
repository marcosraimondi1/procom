/* Includes ------------------------------------------------------------------*/
#include "lwip/pbuf.h"
#include "lwip/udp.h"
#include "lwip/tcp.h"
#include <string.h>
#include <stdio.h>
#include <fsl.h>

/* Private typedef -----------------------------------------------------------*/
/* Private define ------------------------------------------------------------*/
#define UDP_SERVER_PORT    3001   /* define the UDP local connection port */
#define UDP_CLIENT_PORT    3001   /* define the UDP remote connection port */
#define METADATA_SIZE	   16     /* define metadata size of each udp transfer in bytes, multiple of 4 */
/* Private macro -------------------------------------------------------------*/
/* Private variables ---------------------------------------------------------*/
/* Private function prototypes -----------------------------------------------*/
void udp_echoserver_receive_callback(void *arg, struct udp_pcb *upcb, struct pbuf *p, const ip_addr_t *addr, u16_t port);

/* Private functions ---------------------------------------------------------*/

/**
  * @brief  Process received datagram.
  * @param  p received pbuf pointer.
  * @retval None
  */
void process_data(struct pbuf* p)
{
	register int a0;
	register int a1;
	int i, j, start_i;

	// extract metadata
	u8 *payload = p->payload;
    u8 kernel = payload[0];

    register int b0;
    b0 = kernel;
	putfslx(b0,  1, FSL_DEFAULT);

	start_i = METADATA_SIZE;

	// process data
	// PBUF MAX SIZE = 1480 bytes
	u32 val;
    while (p!=NULL)
	{
		payload = p->payload;
		for (i=start_i; i < (p->len); i+=4)
		{
			val = (payload[i]) | (payload[i+1] << 8) | (payload[i+2] << 16) | (payload[i+3] << 24);

			a0 = val;
			putfslx(a0,  0, FSL_DEFAULT);
			for (j=0;j<2;j+=1){}
			getfslx(a1,  0, FSL_DEFAULT);
			payload[i] = a1;
			payload[i]   = a1 & 0xFF;
			payload[i+1] = (a1 >> 8) & 0xFF;
			payload[i+2] = (a1 >> 16) & 0xFF;
			payload[i+3] = (a1 >> 24) & 0xFF;
		}

		start_i = 0;
		p = p->next;
	}
}



/**
  * @brief  Initialize the server application.
  * @param  None
  * @retval None
  */
void udp_echoserver_init(void)
{
   struct udp_pcb *upcb;
   err_t err;

   /* Create a new UDP control block  */
   upcb = udp_new();
   if (!upcb) {
		xil_printf("UDP server: Error creating PCB. Out of Memory\r\n");
		return;
	}

   if (upcb)
   {
     /* Bind the upcb to the UDP_PORT port */
     /* Using IP_ADDR_ANY allow the upcb to be used by any local interface */
      err = udp_bind(upcb, IP_ADDR_ANY, UDP_SERVER_PORT);

      if(err == ERR_OK)
      {
        /* Set a receive callback for the upcb */
        udp_recv(upcb, udp_echoserver_receive_callback, NULL);
      }
  	 if (err != ERR_OK) {
  		xil_printf("UDP server: Unable to bind to port");
  		xil_printf(" %d: err = %d\r\n", UDP_SERVER_PORT, err);
  		udp_remove(upcb);
  		return;
  	 }
   }
   xil_printf("UDP echo server started @ port %d\n\r", UDP_SERVER_PORT);
}



/**
  * @brief This function is called when an UDP datagrm has been received on the port UDP_PORT.
  * @param arg user supplied argument (udp_pcb.recv_arg)
  * @param pcb the udp_pcb which received data
  * @param p the packet buffer that was received
  * @param addr the remote IP address from which the packet was received
  * @param port the remote port from which the packet was received
  * @retval None
  */
void udp_echoserver_receive_callback(void *arg, struct udp_pcb *upcb, struct pbuf *p, const ip_addr_t *addr, u16_t port)
{
	/* Connect to the remote client */
	struct pbuf *original_ptr = p;
	if (udp_connect(upcb, addr, UDP_CLIENT_PORT) == ERR_OK) {

		/* PROCESS DATA */
		process_data(p);



		/* END PROCESS */

		/* Tell the client that we have accepted it */
		if (udp_send(upcb, original_ptr) == ERR_OK) {
			/* free the UDP connection, so we can accept new clients */
			udp_disconnect(upcb);
		} else {
			xil_printf("udp_send failed   ");
		}
	}
	else {
		xil_printf("udp_connect failed   ");
	}

	/* Free the p buffer */
	pbuf_free(original_ptr);

}

