`include "uvm_pkg.sv"
import uvm_pkg::*;
`include "axi_common.sv"
`include "axi_tx.sv"
`include "axi_intrf.sv"
`include "axi_drv.sv"
`include "axi_responder.sv"
`include "axi_sqr.sv"
`include "axi_mon.sv"
`include "axi_cov.sv"
`include "axi_master_agent.sv"
`include "axi_slave_agent.sv"
`include "axi_sbd.sv"
`include "axi_env.sv"
`include "axi_assertion.sv"
`include "axi_seq_lib.sv"
`include "test_lib.sv"
module top_tb;
reg clk,rst;
axi_intrf pif(clk,rst);
axi_assertion axi_assertion_i(pif);
initial begin
	uvm_resource_db#(virtual axi_intrf)::set("GLOBAL","VIF",pif,null);
end
initial begin
	clk=0;
	forever #5 clk=~clk;
end
initial begin
	rst=1;
	repeat(2)@(posedge clk);
	rst=0;
end
initial begin
	run_test("axi_nwr_nrd_test");
end
initial begin
$fsdbDumpfile("axi.fsdb");
$fsdbDumpvars(1);
end
endmodule
