class axi_mon extends uvm_monitor;
uvm_analysis_port#(axi_tx) ap_port;
`uvm_component_utils(axi_mon)
`NEW_COMP
axi_tx tx;
virtual axi_intrf vif;
function void build_phase(uvm_phase phase);
ap_port=new("ap_port",this);
uvm_resource_db#(virtual axi_intrf)::read_by_name("GLOBAL","VIF",vif,this);
endfunction
task run();
forever begin
@(posedge vif.aclk);
if(vif.awvalid==1 && vif.awready==1)begin//this only confirms completion of write_addr phase not the entire tx
tx=axi_tx::type_id::create("tx");
tx.addr=vif.awaddr;
tx.id=vif.awid;
tx.burst_len=vif.awlen;
tx.burst_size=vif.awsize;
tx.burst_type=vif.awburst;
tx.wr_rd=1;
end
if(vif.wvalid==1 && vif.wready==1)begin
tx.dataQ.push_back(vif.wdata);
tx.strbQ.push_back(vif.wstrb);
end
if(vif.bvalid==1 && vif.bready==1)begin
tx.resp=vif.bresp;
$display("printing monitor collected write tx");
tx.print();
ap_port.write(tx);
end
if(vif.arvalid==1 && vif.arready==1)begin//only completion of read addr phase
tx=axi_tx::type_id::create("tx");
tx.addr=vif.araddr;
tx.id=vif.arid;
tx.burst_len=vif.arlen;
tx.burst_size=vif.arsize;
tx.burst_type=vif.arburst;
tx.wr_rd=0;
end
if(vif.rvalid==1 && vif.rready==1)begin//check for rlast then tx completed
tx.dataQ.push_back(vif.rdata);
tx.resp=vif.rresp;
if(vif.rlast==1) 
	$display("printing monitor collected read tx");
	ap_port.write(tx);
end
end
endtask
endclass
