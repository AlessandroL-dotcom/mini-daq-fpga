module simple_fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 16
) (
    input wire clk, 
    input wire wr_en,
    input wire rd_en,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire rst,
    output reg [DATA_WIDTH-1:0] data_out,
    output wire full,
    output wire empty 
);


    
    // memoria interna della FIFO
  
    // array di DEPTH parole, ciascuna larga DATA_WIDTH bit
   
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    
   
    // puntatori di scrittura e lettura
    
    // $clog2(DEPTH) calcola quanti bit servono per contare fino a DEPTH-1
    // Esempio: DEPTH=16 → $clog2(16)=4 → wr_ptr è largo 5 bit


    reg [$clog2(DEPTH):0] wr_ptr = 0;
    reg [$clog2(DEPTH):0] rd_ptr = 0;



    
    // contatore di elementi presenti nella FIFO
   
    // $clog2(DEPTH)+1 garantisce abbastanza bit per contare fino a DEPTH

    reg [$clog2(DEPTH)+1:0] count = 0;


  
    // stato
 


    assign full = (count == DEPTH);
    assign empty = (count == 0);


   
    // logica 
   

    always @(posedge clk or posedge rst) begin
       if (rst) begin 
          wr_ptr <= 0;
          rd_ptr <= 0;
          count <= 0;
          data_out <= 0;
        end else begin
           //scrittura
           if (wr_en && !full) begin
              mem[wr_ptr] <= data_in;
              wr_ptr <= wr_ptr + 1;
              count <= count + 1;
            end 
            //lettura
            if (rd_en && !empty) begin
                data_out <= mem[rd_ptr];  // Legge il dato dalla FIFO
                rd_ptr <= rd_ptr + 1;     // Incrementa il puntatore di lettura
                count <= count - 1;       // Diminuisce numero di elementi
            end
        end
    end

endmodule
