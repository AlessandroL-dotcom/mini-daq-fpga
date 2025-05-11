module event_generator (
    input clk,            // Clock di sistema
    input rst,            // Reset asincrono
    output reg [31:0] data_out,  // 
    output reg valid      // 
);

    reg [31:0] counter;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_out <= 0;
            valid <= 0;
            counter <= 0;
        end else begin
            counter <= counter + 1;

            if (counter % 50000 == 0) begin 
                data_out <= counter;
                valid <= 1;
            end else begin
                valid <= 0;
            end
        end
    end

endmodule
