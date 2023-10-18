`timescale 1ns / 1ps

module DPBRAM #
(
                    parameter integer DWIDTH = 16,              // DPRAM Data
                    parameter integer AWIDTH = 16,              // DPRAM Memory Depth에 따라서 수정 필요
                    parameter integer MEM_SIZE = 10000          // DPRAM Memory Depth
)

(
                    input clk,
                    input [AWIDTH -1 : 0] addr0,
                    input ce0,
                    input we0,
                    input [DWIDTH - 1 : 0]din0,
                    output reg [DWIDTH -1 : 0] dout0,
                    
                    input [AWIDTH - 1 : 0] addr1,
                    input ce1,
                    input we1,
                    input [DWIDTH - 1 : 0] din1,
    
                    output reg [DWIDTH - 1 : 0] dout1
);
 
(* RAM_STYLE = "BLOCK"*) reg [DWIDTH -1 :0] ram[0:MEM_SIZE-1];

always@(posedge clk) 
begin
    if(ce0)
    begin
        if(we0)
            ram[addr0] <= din0;
        else
            dout0 <= ram[addr0];
    end
end

always@(posedge clk) 
begin
    if(ce1)
    begin
        if(we1)
            ram[addr1] <= din1;
        else
            dout1 <= ram[addr1];
    end
end
            
endmodule