interface axi_intrf(input aclk,arst);
//write channel signals
bit [3:0]awid;
bit [31:0]awaddr;
bit [3:0]awlen;
bit [2:0]awsize;
bit [1:0]awburst;
bit [1:0]awlock;
bit awvalid;
bit awready;
bit [3:0]wid;
bit [31:0]wdata;
bit [3:0]wstrb;
bit wlast;
bit wvalid;
bit wready;
bit [3:0]bid;
bit [1:0]bresp;
bit bvalid;
bit bready;
//read channel signals
bit [3:0]arid;
bit [31:0]araddr;
bit [3:0]arlen;
bit [2:0]arsize;
bit [1:0]arburst;
bit [1:0]arlock;
bit arvalid;
bit arready;
bit [3:0]rid;
bit [31:0]rdata;
bit rlast;
bit rvalid;
bit rready;
bit [1:0]rresp;

clocking drv_cb@(posedge aclk);
default input #0 output #0;
output awid,awaddr,awlen,awsize,awburst,awlock,awvalid;
input arst,awready,wready;
output wid,wdata,wstrb,wlast,wvalid;
input bid,bresp,bvalid;
output bready;
output arid,araddr,arlen,arsize,arburst,arlock,arvalid;
input arready;
input rid,rdata,rlast,rvalid,rresp;
output rready;//only for rready keep skew at 0
endclocking
clocking mon_cb@(posedge aclk);
default input #0 ;
input awid,awaddr,awlen,awsize,awburst,awlock,awvalid;
input arst,awready,wready;
input wid,wdata,wstrb,wlast,wvalid;
input bid,bresp,bvalid;
input bready;
input arid,araddr,arlen,arsize,arburst,arlock,arvalid;
input arready;
input rid,rdata,rlast,rvalid,rresp;
input rready;
endclocking
clocking responder_cb@(posedge aclk);
default input #0 output #1;//01 is working
input arst,awid,awaddr,awlen,awsize,awburst,awlock,awvalid;
output awready,wready;
input wid,wdata,wstrb,wlast,wvalid;
input arid,araddr,arlen,arsize,arburst,arlock,arvalid;
output arready;
output rid,rdata,rlast,rvalid,rresp;
input rready,bready;
endclocking
endinterface
