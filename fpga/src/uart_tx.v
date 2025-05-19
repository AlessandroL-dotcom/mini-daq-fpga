//È il modulo che converte un byte parallelo ([7:0]) in un flusso seriale su un pin tx.
//Segue lo standard UART:
//[ START=0 ][ D0 ][ D1 ]...[ D7 ][ STOP=1 ]


module UART_tx#(
    parameter CLK_FREQ = 50000000,
    parameter BAUD_RATE = 9600    // tx/rx 9600 bit per secondo 
)(
     input wire clk,                   // Clock del sistema 50 MHz
    input wire rst,                   // Reset asincrono
    input wire start,                 // Segnale: avvia la trasmissione
    input wire [7:0] data_in,         // Byte da trasmettere
    output reg tx,                    // Linea seriale UART in uscita
    output reg busy                   // Segnale: UART occupata
);

    // Calcolo del numero di cicli di clock per ogni bit UART
    localparam integer BAUD_TICK_COUNT = CLK_FREQ / BAUD_RATE;

    // Contatore per generare un tick ogni BAUD_TICK_COUNT cicli
    reg [$clog2(BAUD_TICK_COUNT):0] baud_counter = 0;

    // Segnale che diventa alto ogni volta che è ora di inviare il prossimo bit
    reg baud_tick;

    //FSM per la trasmissione del dato