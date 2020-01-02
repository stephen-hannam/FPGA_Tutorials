// from: https://stackoverflow.com/questions/29313913/how-to-parameterize-a-case-statement-with-dont-cares/29322849#29322849

module pri_enc #(parameter WIDTH=4) (
    input wire [WIDTH-1:0] i,  // input data
    input wire [WIDTH-1:0] c,  // input control
    output reg [WIDTH-1:0] o   // output data
    );

    // Deal with the most significant bit case apart
    always @* begin
        if (c[WIDTH-1]==1'b1)
            o[WIDTH-1] = i[WIDTH-1];
        else
            o[WIDTH-1] = 1'b0;
    end

    // Deal with the rest of bits
    genvar idx;
    generate
    for (idx = WIDTH-2; idx >=0; idx = idx-1) begin :gen_cases
        always @* begin
            if (c[idx]==1'b1 && c[WIDTH-1:idx+1]=='b0)
                o[idx] = i[idx];
            else
                o[idx] = 1'b0;
        end
     end
     endgenerate
endmodule

//module enc
//#(
//  parameter IW = 8,
//  parameter OW = `M(IW)
//)(
//  input      [IW-1:0] in,
//  output reg [OW:0]   out
//);
//
//  integer i;
//  always @* begin
//    out = 0; 
//    for (i = IW-1; i >= 0; i = i - 1) begin
//      if (in[i]) begin
//        out = i;
//      end
//    end
//  end
//
//endmodule
