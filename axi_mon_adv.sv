
class axi_mon extends uvm_monitor;
uvm_analysis_port#(axi_tx) ap_port;
`uvm_component_utils(axi_mon)
`NEW_COMP
axi_tx writetxA[15:0];
axi_tx readtxA[15:0];
function void build_phase(uvm_phase phase);
ap_port=new("ap_port",this);
endfunction
task run();
forever begin
@(posedge vif.aclk);
if(vif.awvalid==1 && vif.awready==1)begin//this only confirms completion of write_addr phase not the entire writetxA[vif.awid]
name=$sformatf("writetxA[%0d]",vif.awid);
writetxA[vif.awid]=axi_tx::type_id::create(name);
writetxA[vif.awid].addr=vif.awaddr;
writetxA[vif.awid].id=vif.awid;
writetxA[vif.awid].burst_len=vif.awlen;
writetxA[vif.awid].burst_size=vif.awsize;
writetxA[vif.awid].burst_type=vif.awburst;
writetxA[vif.awid].wr_rd=1;
end
if(vif.wvalid==1 && vif.wready==1)begin
writetxA[vif.awid].dataQ.push_back(vif.wdata);
writetxA[vif.awid]=strbQ.push_back(vif.wstrb);
end
if(bvalid==1 && vif.bready==1)begin
writetxA[vif.awid].resp=vif.bresp;
ap_port.write(writetxA[vif.awid]);
end
if(vif.arvalid==1 && vif.arready==1)begin//only completion of read addr phase
readtxA[vif.rid]=axi_tx::type_id::create(name);
readtxA[vif.rid].addr=vif.araddr;
readtxA[vif.rid].id=vif.arid;
readtxA[vif.rid].burst_len=vif.arlen;
readtxA[vif.rid].burst_size=vif.arsize;
readtxA[vif.rid].burst_type=vif.arburst;
readtxA[vif.rid].wr_rd=0;
end
if(vif.rvalid==1 && vif.rready==1)begin//check for rlast then readtxA[vif.rid] completed
readtxA[vif.rid].dataQ.push_back(vif.rdata);
readtxA[vif.rid].resp=vif.rresp;
if(vif.rlast==1) ap_port.write(readtxA[vif.rid]);
end
end
endtask
endclass
