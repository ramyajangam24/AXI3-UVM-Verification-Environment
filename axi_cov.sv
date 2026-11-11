class axi_cov extends uvm_subscriber#(axi_tx);
`uvm_component_utils(axi_cov)
axi_tx tx;
covergroup axi_cg;
ADDR_CP:coverpoint tx.addr{
option.auto_bin_max=8;
}
WR_RD_CP:coverpoint tx.wr_rd{
bins write={1'b1};
bins read={1'b0};
}
BURST_TYPE_CP:coverpoint tx.burst_type{
bins FIXED={2'b00};
bins INCR={2'b01};
bins WRAP={2'b11};
illegal_bins RSVD={2'b11};
}
RESP_CP:coverpoint tx.resp{
bins OKAY={2'b00};
bins EXOKAY={2'b01};
bins SLVERR={2'b10};
bins DECERR={2'b11};
}
BURST_SIZE_CP:coverpoint tx.burst_size{
bins byte_1  ={3'b000};
bins byte_2  ={3'b001};
bins byte_4  ={3'b010};
bins byte_8  ={3'b011};
bins byte_16 ={3'b100};
bins byte_32 ={3'b101};
bins byte_64 ={3'b110};
bins byte_128={3'b111};
}
//cach,pro
ADDR_X_WR_RD_CP:cross ADDR_CP,WR_RD_CP;
endgroup
function new(string name,uvm_component parent);
super.new(name,parent);
axi_cg=new();
endfunction
function void write(axi_tx t);
tx=new t;
axi_cg.sample();
endfunction
endclass

