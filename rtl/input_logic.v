/*
BSD 2-Clause License

Copyright (c) 2019, TDK Electronics, Pawel Wiecha
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
module input_logic
#(
  parameter DATA_WIDTH = 8,
  parameter DATA_SIZE = 6
)
(
  input clk,
  input rst_n,
  // Input IF
  input [DATA_WIDTH-1:0] data_in,
  input data_in_req,
  output reg data_in_ack,
  // Config IF
  input [1:0] ch0_addr,
  input [1:0] ch1_addr,
  input [1:0] ch2_addr,
  input       crc_en
)
  localparam [1:0] IDLE = 2'b00, ADDR_SIZE = 2'b01,
  DATA = 2'b10, DISCARD = 2'b11;

  reg data_in_ack_r;
  reg [DATA_WIDTH-1:0] input_buffer_r;

  reg [DATA_SIZE:0] data_cnt_r;

  // FSM
  reg [1:0] state_r, state_next_c;


  assign data_in_ack = data_in_ack_r;

  //TODO add byte cnt and split logic into modules?

  always @(posedge clk or negedge rst_n)
  begin: input_buffer_r_proc
    if (!rst_n) begin
      input_buffer_r <= {DATA_WIDTH{1'b0}};
    end
    else if (data_in_req) begin
      input_buffer_r <= data_in;
    end

  always @(posedge clk or negedge rst_n)
  begin: req_edge_detect_r_proc
    if (!rst_n) begin
      req_edge_detect_r <= 1'b0;
    end
    else if (data_in_req && !req_edge_detect_r) begin
      req_edge_detect_r <= 1'b1;
    end
    else if ((state_r == DATA || state_r == DISCARD) && state_next_c == IDLE) begin
      req_edge_detect_r <= 1'b0;
    end
  end

  always @(posedge clk or negedge rst_n)
  begin: data_in_ack_r_proc
    if (!rst_n) begin
      data_in_ack_r <= 1'b0;
    end
    else begin
      //set ack hi - add control logic
      if () begin
        data_in_ack_r <= 1'b1;
      //if fifo full - stall
      else begin
        data_in_ack_r <= 1'b0;
      end
    end

    // FSM
    always @(posedge clk or negedge rst_n)
    begin: state_r_proc
      if (!rst_n) begin
        state_r <= 2'd0;
      else begin
        state_r <= state_next_c;
      end
    end

    always @(*)
    begin: state_next_c_proc
      case (state_r)
        IDLE:
          if (req_edge_detect_r) begin
            state_next_c = ADDR_SIZE;
          end
          else begin
            state_next_c = IDLE;
          end
        ADDR_SIZE:
          if (bad_addr_c) begin
            state_next_c = DISCARD;
          end
          else begin
            state_next_c = DATA;
          end
        DATA:
          if (crc_en && bad_crc_c) begin
            state_next_c = DISCARD
          end
          else if (data_cnt_r == {DATA_SIZE{1'b0}}) begin
            state_next_c = IDLE;
          end
          else begin
            state_next_c = DATA;
          end
        DISCARD: //wait for pkt to end, ack all bytes
          if (data_cnt_r == {DATA_SIZE{1'b0}}) begin
            state_next_c = IDLE;
          end
          else begin
            state_next_c = DISCARD;
          end
      endcase
    end




endmodule
