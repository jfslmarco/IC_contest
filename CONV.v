
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output	reg	busy,	
	input		ready,	
			
	output	reg	[11:0] iaddr,
	input	[19:0] idata,	
	
	output	reg 	cwr,
	output	reg 	[11:0] caddr_wr,
	output	reg 	[19:0] cdata_wr,
	
	output	reg 	crd,
	output	reg 	[11:0] caddr_rd,
	input	 	[19:0] cdata_rd,
	
	output	reg 	[2:0] csel
	
	);
//////////////////////////////////////////
parameter signed ker0_0 = 20'h0A89E;      //Pixel 0: 6.586609e-01
parameter signed ker1_0 = 20'hFDB55;      //Pixel 1: -1.432343e-01
parameter signed ker0_1 = 20'h092D5;      //Pixel 2: 5.735626e-01
parameter signed ker1_1 = 20'h02992;      //Pixel 3: 1.623840e-01
parameter signed ker0_2 = 20'h06D43;     //Pixel 4: 4.268036e-01
parameter signed ker1_2 = 20'hFC994;     //Pixel 5: -2.125854e-01
parameter signed ker0_3 = 20'h01004;     //Pixel 6: 6.256104e-02
parameter signed ker1_3 = 20'h050FD;     //Pixel 7: 3.163605e-01
parameter signed ker0_4 = 20'hF8F71;     //Pixel 8: -4.396820e-01
parameter signed ker1_4 = 20'h02F20;     //Pixel 9: 1.840820e-01
parameter signed ker0_5 = 20'hF6E54;     //Pixel 10: -5.690308e-01
parameter signed ker1_5 = 20'h0202D;     //Pixel 11: 1.256866e-01
parameter signed ker0_6 = 20'hFA6D7;     //Pixel 12: -3.482819e-01
parameter signed ker1_6 = 20'h03BD7;     //Pixel 13: 2.337494e-01
parameter signed ker0_7 = 20'hFC834;     //Pixel 14: -2.179565e-01
parameter signed ker1_7 = 20'hFD369;     //Pixel 15: -1.741791e-01
parameter signed ker0_8 = 20'hFAC19;     //Pixel 16: -3.277435e-01
parameter signed ker1_8 = 20'h05E68;     //Pixel 17: 3.687744e-01

parameter signed bias_ker0 = 20'h01310;     //Pixel 0: 7.446289e-02
parameter signed bias_ker1 = 20'hF7295;     //Pixel 1: -5.524139e-01

/*reg busy, cwr, crd;
reg [11:0] iaddr;
reg [11:0] caddr_wr;
reg	[19:0] cdata_wr;
reg [11:0] caddr_rd;
reg [2:0] csel;
*/

reg [4:0] cur_st, nxt_st;
parameter IDLE = 5'd0,
			CONV_0 = 5'd1,
			WAIT_CONV_0 = 5'd2,
			CONV_1 = 5'd3,
			WAIT_CONV_1 = 5'd4,
			CONV_2 = 5'd5,
			WAIT_CONV_2 = 5'd6,
			CONV_3 = 5'd7,
			WAIT_CONV_3 = 5'd8,
			CONV_4 = 5'd9,
			WAIT_CONV_4 = 5'd10,
			CONV_5 = 5'd11,
			WAIT_CONV_5 = 5'd12,
			CONV_6 = 5'd13,
			WAIT_CONV_6 = 5'd14,
			CONV_7 = 5'd15,
			WAIT_CONV_7 = 5'd16,
			CONV_8 = 5'd17,
			WAIT_CONV_8 = 5'd18,
			CONV_FINISH = 5'd19,
			
			MAX_KER0_LOAD = 5'd20,
			MAX_KER0_OUT = 5'd21,
			MAX_KER1_LOAD = 5'd22,
			MAX_KER1_OUT = 5'd23,
			MAX_FINISH = 5'd24,
			
			FLAT_KER0_LOAD = 5'd25,
			FLAT_KER0_OUT = 5'd26,
			FLAT_KER1_LOAD = 5'd27,
			FLAT_KER1_OUT = 5'd28,
			ALL_FINISH = 5'd29;
			
reg signed [19:0] idata_reg;

reg signed [19:0] conv_mul_a;
reg signed [19:0] ker0_weight, ker1_weight;
reg signed [39:0] conv_ker0_mul, conv_ker1_mul;
reg signed [39:0] conv_ker0_mul_reg, conv_ker1_mul_reg;

wire signed [19:0] conv_ker0_mul_reg_before, conv_ker1_mul_reg_before;
wire signed [19:0] conv_ker0_mul_reg_20bit, conv_ker1_mul_reg_20bit;
reg signed [19:0] conv_ker0_result, conv_ker1_result;

reg [3:0] counter_one_pixel;
reg [5:0] ptr_x, ptr_y;

reg conv_finsih, max_finsih;


reg [2:0] counter_layer1;
reg [4:0] layer1_ptr_x, layer1_ptr_y;

reg [10:0] layer2_addr;

reg [19:0] layer1_reg;
	
always@(posedge clk or posedge reset)
if(reset)
	cur_st <= IDLE;
else
	cur_st <= nxt_st;
	
always@(*)
case(cur_st)
	IDLE     : nxt_st = (ready)? CONV_0 : IDLE;
	CONV_0   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_0 : CONV_0;
	WAIT_CONV_0 : nxt_st = CONV_1;
	CONV_1   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_1 : CONV_1;
	WAIT_CONV_1 : nxt_st = (ptr_x==6'd62)? CONV_2 : CONV_1;
	CONV_2   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_2 : CONV_2;
	WAIT_CONV_2 : nxt_st = CONV_3;
	CONV_3   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_3 : CONV_3;
	WAIT_CONV_3 : nxt_st = CONV_4;
	CONV_4   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_4 : CONV_4;
	WAIT_CONV_4 : nxt_st = (ptr_x==6'd62)? CONV_5 : CONV_4;
	CONV_5   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_5 : CONV_5;
	WAIT_CONV_5 : nxt_st = (ptr_y==6'd62 && ptr_x==6'd63)? CONV_6 : CONV_3;
	CONV_6   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_6 : CONV_6;
	WAIT_CONV_6 : nxt_st = CONV_7;
	CONV_7   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_7 : CONV_7;
	WAIT_CONV_7 : nxt_st = (ptr_x==6'd62)? CONV_8 : CONV_7;
	CONV_8   : nxt_st = (counter_one_pixel==4'd10)? WAIT_CONV_8 : CONV_8;
	WAIT_CONV_8 : nxt_st = CONV_FINISH;
	CONV_FINISH : nxt_st = MAX_KER0_LOAD;
	
	MAX_KER0_LOAD : nxt_st = (counter_layer1==3'd4)? MAX_KER0_OUT : MAX_KER0_LOAD;
	MAX_KER0_OUT : nxt_st = MAX_KER1_LOAD;
	MAX_KER1_LOAD : nxt_st = (counter_layer1==3'd4)? MAX_KER1_OUT : MAX_KER1_LOAD;
	MAX_KER1_OUT : nxt_st = (layer1_ptr_x==5'd31 && layer1_ptr_y==5'd31)? MAX_FINISH : MAX_KER0_LOAD;
	MAX_FINISH : nxt_st = FLAT_KER0_LOAD;
	
	FLAT_KER0_LOAD : nxt_st = FLAT_KER0_OUT;
	FLAT_KER0_OUT : nxt_st = FLAT_KER1_LOAD;
	FLAT_KER1_LOAD : nxt_st = FLAT_KER1_OUT;
	FLAT_KER1_OUT : nxt_st = (layer1_ptr_x==5'd31 && layer1_ptr_y==5'd31)? ALL_FINISH : FLAT_KER0_LOAD;
	default  : nxt_st = ALL_FINISH;
endcase


always@(posedge clk or posedge reset)
if(reset)
	counter_one_pixel <= 4'd0;
else if(counter_one_pixel==4'd11 || conv_finsih)
	counter_one_pixel <= 4'd0;
else if(cur_st!=IDLE)
	counter_one_pixel <= counter_one_pixel + 1;

always@(posedge clk or posedge reset)
if(reset)
begin
	ptr_x <= 0;
	ptr_y <= 0;
end
else if(counter_one_pixel==4'd11)
	if(ptr_x==6'd63)
	begin
		ptr_x <= 0;
		ptr_y <= ptr_y+1;
	end
	else
		ptr_x <= ptr_x+1;

		
always@(*)
case(counter_one_pixel)
	4'd0 : iaddr = {ptr_y-1'd1, ptr_x-1'd1};
	4'd1 : iaddr = {ptr_y-1'd1, ptr_x};
	4'd2 : iaddr = {ptr_y-1'd1, ptr_x+1'd1};
	4'd3 : iaddr = {ptr_y, ptr_x-1'd1};
	4'd4 : iaddr = {ptr_y, ptr_x};	
	4'd5 : iaddr = {ptr_y, ptr_x+1'd1};	
	4'd6 : iaddr = {ptr_y+1'd1, ptr_x-1'd1};	
	4'd7 : iaddr = {ptr_y+1'd1, ptr_x};
	4'd8 : iaddr = {ptr_y+1'd1, ptr_x+1'd1};
	default : iaddr = 0; 
endcase	

always@(posedge clk)
	idata_reg <= idata;
		

		
always@(*)
case({cur_st, counter_one_pixel})
	{CONV_0,4'd1}, {CONV_0,4'd2}, {CONV_0,4'd3}, {CONV_0,4'd4}, {CONV_0,4'd7}   :  conv_mul_a = 0;
	{CONV_1,4'd1}, {CONV_1,4'd2}, {CONV_1,4'd3} :  conv_mul_a = 0;
	{CONV_2,4'd1}, {CONV_2,4'd2}, {CONV_2,4'd3}, {CONV_2,4'd6}, {CONV_2,4'd9} :  conv_mul_a = 0;
	{CONV_3,4'd1}, {CONV_3,4'd4}, {CONV_3,4'd7} :  conv_mul_a = 0;
	{CONV_5,4'd3}, {CONV_5,4'd6}, {CONV_5,4'd9} :  conv_mul_a = 0;
	{CONV_6,4'd1}, {CONV_6,4'd4}, {CONV_6,4'd7}, {CONV_6,4'd8}, {CONV_6,4'd9} :  conv_mul_a = 0;
	{CONV_7,4'd7}, {CONV_7,4'd8}, {CONV_7,4'd9} :  conv_mul_a = 0;
	{CONV_8,4'd3}, {CONV_8,4'd6}, {CONV_8,4'd7}, {CONV_8,4'd8}, {CONV_8,4'd9} :  conv_mul_a = 0;
	default : conv_mul_a = idata_reg; 
endcase		

always@(*)
case(counter_one_pixel)
	4'd1 : ker0_weight = ker0_0;
	4'd2 : ker0_weight = ker0_1;
	4'd3 : ker0_weight = ker0_2;
	4'd4 : ker0_weight = ker0_3;
	4'd5 : ker0_weight = ker0_4;	
	4'd6 : ker0_weight = ker0_5;	
	4'd7 : ker0_weight = ker0_6;	
	4'd8 : ker0_weight = ker0_7;
	4'd9 : ker0_weight = ker0_8;
	default : ker0_weight = 0; 
endcase

always@(*)
case(counter_one_pixel)
	4'd1 : ker1_weight = ker1_0;
	4'd2 : ker1_weight = ker1_1;
	4'd3 : ker1_weight = ker1_2;
	4'd4 : ker1_weight = ker1_3;
	4'd5 : ker1_weight = ker1_4;	
	4'd6 : ker1_weight = ker1_5;	
	4'd7 : ker1_weight = ker1_6;	
	4'd8 : ker1_weight = ker1_7;
	4'd9 : ker1_weight = ker1_8;
	default : ker1_weight = 0; 
endcase

always@(*)
	conv_ker0_mul = conv_mul_a * ker0_weight;

always@(*)
	conv_ker1_mul = conv_mul_a * ker1_weight;

	
always@(posedge clk or posedge reset)
if(reset)
	conv_ker0_mul_reg <= 0;
else if(counter_one_pixel==0)
	conv_ker0_mul_reg <= 0;
else if(counter_one_pixel!=0)
	conv_ker0_mul_reg <= conv_ker0_mul_reg + conv_ker0_mul;
	
always@(posedge clk or posedge reset)
if(reset)
	conv_ker1_mul_reg <= 0;
else if(counter_one_pixel==0)
	conv_ker1_mul_reg <= 0;
else if(counter_one_pixel!=0)
	conv_ker1_mul_reg <= conv_ker1_mul_reg + conv_ker1_mul;
	

always@(posedge clk or posedge reset)
if(reset)
	conv_finsih <= 0;
else if(cur_st==CONV_FINISH)
	conv_finsih <= 1;
	
	
//////////////////////////////////////////////	
always@(posedge clk or posedge reset)//
if(reset)
	cwr <= 0;
else if(counter_one_pixel==4'd10 || counter_one_pixel==4'd11 || (((cur_st==MAX_KER0_LOAD)||(cur_st==MAX_KER1_LOAD))&&counter_layer1==3'd4) || (cur_st==FLAT_KER0_LOAD || cur_st==FLAT_KER1_LOAD))
	cwr <= 1;
else
	cwr <= 0;

always@(posedge clk or posedge reset)//
if(reset)
	caddr_wr <= 0;
else
	caddr_wr <= (conv_finsih)? (cur_st==FLAT_KER0_LOAD || cur_st==FLAT_KER1_LOAD)? layer2_addr : {layer1_ptr_y,layer1_ptr_x} :{ptr_y, ptr_x};

	
assign conv_ker0_mul_reg_before = conv_ker0_mul_reg[35:16];
assign conv_ker1_mul_reg_before = conv_ker1_mul_reg[35:16];
	
assign conv_ker0_mul_reg_20bit = (conv_ker0_mul_reg[15])? conv_ker0_mul_reg_before + 1'd1 : conv_ker0_mul_reg_before;
assign conv_ker1_mul_reg_20bit = (conv_ker1_mul_reg[15])? conv_ker1_mul_reg_before + 1'd1 : conv_ker1_mul_reg_before;
	
always@(*)
	conv_ker0_result = conv_ker0_mul_reg_20bit + bias_ker0;
always@(*)
	conv_ker1_result = conv_ker1_mul_reg_20bit + bias_ker1;
	
always@(posedge clk)
if(cur_st==CONV_0 || cur_st==CONV_1 || cur_st==CONV_2 || cur_st==CONV_3 || cur_st==CONV_4 || cur_st==CONV_5 || cur_st==CONV_6 || cur_st==CONV_7 || cur_st==CONV_8)
	cdata_wr <=  (conv_ker0_result[19])? 0 : conv_ker0_result;
else if(cur_st==WAIT_CONV_0 || cur_st==WAIT_CONV_1 || cur_st==WAIT_CONV_2 || cur_st==WAIT_CONV_3 || cur_st==WAIT_CONV_4 || cur_st==WAIT_CONV_5 || cur_st==WAIT_CONV_6 || cur_st==WAIT_CONV_7 || cur_st==WAIT_CONV_8)
	cdata_wr <=  (conv_ker1_result[19])? 0 : conv_ker1_result;
else if((cur_st==MAX_KER0_LOAD || cur_st==MAX_KER1_LOAD) && counter_layer1== 3'd4)
	cdata_wr <= layer1_reg;
else if(layer1_ptr_x==0 && layer1_ptr_y==0 &&cur_st==FLAT_KER0_LOAD)
	cdata_wr <= 0;
else if(cur_st==FLAT_KER0_LOAD || cur_st==FLAT_KER1_LOAD)//
	cdata_wr <= cdata_rd;
	
////////////////////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge reset)
if(reset)
	csel <= 0;
else if(counter_one_pixel==4'd10)
	csel <= 3'b001;
else if(counter_one_pixel==4'd11)
	csel <= 3'b010;
else if(nxt_st==MAX_KER0_LOAD)
	csel <= 3'b001;
else if(nxt_st==MAX_KER1_LOAD)
	csel <= 3'b010;
else if(nxt_st==MAX_KER0_OUT)
	csel <= 3'b011;
else if(nxt_st==MAX_KER1_OUT)
	csel <= 3'b100;
else if(cur_st==MAX_FINISH || cur_st==FLAT_KER1_OUT)
	csel <= 3'b011;
else if(cur_st==FLAT_KER0_OUT)
	csel <= 3'b100;
else if(cur_st==FLAT_KER0_LOAD || cur_st==FLAT_KER1_LOAD)
	csel <= 3'b101;
/////////////////////////////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge reset)
if(reset)
	counter_layer1 <= 0;
else if(counter_layer1==3'd5)
	counter_layer1 <= 0;
else if(cur_st==MAX_KER0_LOAD || cur_st==MAX_KER1_LOAD)
	counter_layer1 <= counter_layer1 +1;

always@(posedge clk or posedge reset)
if(reset)
begin
	layer1_ptr_x <= 0;
	layer1_ptr_y <= 0;
end
else if((cur_st==MAX_KER1_OUT &&counter_layer1==3'd5) || cur_st==FLAT_KER1_OUT)
begin
	if(layer1_ptr_x==5'd31)
	begin
		layer1_ptr_y <= layer1_ptr_y + 1;
		layer1_ptr_x <= 0;
	end
	else
		layer1_ptr_x <= layer1_ptr_x + 1;
end





always@(posedge clk or posedge reset)
if(reset)
	crd <= 0;
else if((cur_st==MAX_KER0_OUT || cur_st==MAX_KER1_OUT) || ((cur_st==MAX_KER0_LOAD ||cur_st==MAX_KER1_LOAD)&&counter_layer1<=3'd2) || (cur_st==MAX_FINISH || cur_st==FLAT_KER0_OUT || cur_st==FLAT_KER1_OUT))
	crd <= 1;
else
	crd <= 0;
	

always@(*)
case(counter_layer1)
	2'd0 : caddr_rd = (max_finsih)? {layer1_ptr_y, layer1_ptr_x} : {layer1_ptr_y,1'd0, layer1_ptr_x,1'd0};//
	2'd1 : caddr_rd = {layer1_ptr_y,1'd0, layer1_ptr_x,1'd1};
	2'd2 : caddr_rd = {layer1_ptr_y,1'd1, layer1_ptr_x,1'd0};
	2'd3 : caddr_rd = {layer1_ptr_y,1'd1, layer1_ptr_x,1'd1};
	default : caddr_rd = 0;
endcase


always@(posedge clk or posedge reset)
if(reset)
	layer1_reg <= 20'd0;
else if((layer1_ptr_x==0 &&layer1_ptr_y==0 && cur_st==MAX_KER0_LOAD )||(cur_st==MAX_KER0_OUT || cur_st==MAX_KER1_OUT))
	layer1_reg <= 20'd0;
else if(cur_st==MAX_KER0_LOAD || cur_st==MAX_KER1_LOAD)
	if(cdata_rd>=layer1_reg)
		layer1_reg <= cdata_rd;
		

		
always@(posedge clk or posedge reset)
if(reset)
	max_finsih <= 0;
else if(cur_st==MAX_FINISH)
	max_finsih <= 1;	

///////////////////////////////////////////////////////////////////////




always@(*)
case(cur_st)
	FLAT_KER0_LOAD : layer2_addr = {layer1_ptr_y,layer1_ptr_x,1'd0};
	FLAT_KER1_LOAD : layer2_addr = {layer1_ptr_y,layer1_ptr_x,1'd1};
	default : layer2_addr = {layer1_ptr_y,layer1_ptr_x};//
endcase












































	
always@(posedge clk or posedge reset)
if(reset)
	busy <= 0;
else if(ready)
	busy <= 1;
else if(cur_st==ALL_FINISH)
	busy <= 0;

endmodule




