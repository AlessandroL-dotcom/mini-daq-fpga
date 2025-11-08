//È il modulo che converte un byte parallelo ([7:0]) in un flusso seriale su un pin tx.
//Segue lo standard UART:
//[ START=0 ][ D0 ][ D1 ]...[ D7 ][ STOP=1 ]


module UART_tx#(
    parameter CLK_FREQ  = 50000000,
    parameter BAUD_RATE = 9600    // tx/rx 9600 bit per secondo 
)(
    input  wire        clk,        // Clock del sistema 50 MHz
    input  wire        rst,        // Reset asincrono
    input  wire        start,      // Segnale: avvia la trasmissione
    input  wire [7:0]  data_in,    // Byte da trasmettere
    output reg         tx,         // Linea seriale UART in uscita
    output reg         busy        // Segnale: UART occupata
);

// Calcolo del numero di cicli di clock per ogni bit UART
 localparam integer BAUD_TICK_COUNT = CLK_FREQ / BAUD_RATE;

// Contatore per generare un tick ogni BAUD_TICK_COUNT cicli
 reg [$clog2(BAUD_TICK_COUNT):0] baud_counter = 0;

// Segnale che diventa alto ogni volta che è ora di inviare il prossimo bit
reg baud_tick;

 //FSM per la trasmissione del dato
// Stati: IDLE (linea alta), START (bit di start = 0), DATA (8 bit LSB-first), STOP (bit di stop = 1)
typedef enum logic [1:0] {IDLE=2'd0, START=2'd1, DATA=2'd2, STOP=2'd3} state_t;
state_t state = IDLE;

// Registro di shift per i dati e indice del bit in uscita
reg [7:0] shift_reg = 8'h00;   // contiene il byte da trasmettere
reg [2:0] bit_idx   = 3'd0;    // conta da 0 a 7 i bit D0..D7


// generatore di baud_tick

always @(posedge clk or posedge rst) begin
  if (rst) begin
    baud_counter <= 0;
     baud_tick    <= 1'b0;
   end else begin
     if (baud_counter == BAUD_TICK_COUNT-1) begin
        baud_counter <= 0;
        baud_tick    <= 1'b1;      // impulso di 1 ciclo
    end else begin
         baud_counter <= baud_counter + 1'b1;
          baud_tick    <= 1'b0;
            end
        end
    end

   
    // FSM di trasmissione
  
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1;     // linea idle = livello alto
            busy      <= 1'b0;
            shift_reg <= 8'h00;
            bit_idx   <= 3'd0;
        end else begin
            case (state)

         IDLE: begin
           tx   <= 1'b1;   // linea a riposo alta
           busy <= 1'b0;
         // accetto una nuova trasmissione quando start=1
           if (start) begin
              shift_reg   <= data_in;    // carico il dato
              bit_idx     <= 3'd0;
               busy        <= 1'b1;
               state       <= START;
                        // (riporto il contatore a zero così lo START dura un bit pieno)
                        // Nota: non tocco baud_tick, solo il contatore
                    end
                end

                START: begin
                    tx <= 1'b0;  // bit di start = 0
                    if (baud_tick) begin
                        state <= DATA;   // dopo 1 bit-time, vai ai dati
                    end
                end

                DATA: begin
                    tx <= shift_reg[0]; // esco LSB per primo
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[7:1]}; // shift a destra
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            state   <= STOP;   // dopo l'ottavo bit vai allo stop
                        end else begin
                            bit_idx <= bit_idx + 1'b1;
                        end
                    end
                end

                STOP: begin
                    tx <= 1'b1; // bit di stop = 1
                    if (baud_tick) begin
                        state <= IDLE;  // finito: torna a idle
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
