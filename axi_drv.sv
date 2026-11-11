class axi_drv extends uvm_driver#(axi_tx);
virtual axi_intrf vif;
semaphore smp_wd=new(1);
`uvm_component_utils(axi_drv)
`NEW_COMP
task run();
axi_tx tx;
uvm_resource_db#(virtual axi_intrf)::read_by_name("GLOBAL","VIF",vif,this);
wait(vif.arst==0);
forever begin
seq_item_port.get_next_item(req);
tx=new req;
fork
drive_tx(req);
join_none
seq_item_port.item_done();
#100;
end
endtask
task drive_tx(axi_tx tx);
//we need to implement the behavior of axi_write protocol
if(tx.wr_rd==1)begin
write_addr(tx);
write_data(tx);//this needs for loop
write_resp(tx);
end
else begin
read_addr(tx);
read_data(tx);//this needs for loop 
end
endtask 
//drive signals regarding to write addr channel
task write_addr(axi_tx tx);
@(posedge vif.aclk);
vif.awid=tx.id;
vif.awaddr=tx.addr;
vif.awlen=tx.burst_len;
vif.awburst=tx.burst_type;
vif.awsize=tx.burst_size;
vif.awvalid=1;
wait(vif.awready==1);
@(posedge vif.aclk);
vif.awvalid=0;
vif.awid=0;
vif.awaddr=0;
vif.awlen=0;
vif.awburst=0;
vif.awsize=0;
endtask

task write_data(axi_tx tx);
	smp_wd.get(1);
for(int i=0;i<=tx.burst_len;i++)begin
@(posedge vif.aclk);
vif.wid=tx.id;
vif.wdata=tx.dataQ.pop_front();
vif.wstrb=tx.strbQ.pop_front();
vif.wlast=(i==tx.burst_len)?1:0;
vif.wvalid=1;
wait(vif.wready==1);
end
@(posedge vif.aclk);
vif.wid=0;
vif.wdata=0;
vif.wstrb=0;
vif.wlast=0;
vif.wvalid=0;
smp_wd.put(1);
endtask
task write_resp(axi_tx tx);
while(vif.bvalid==0)begin
//as long as bvalid=0 dont proceed further 
@(posedge vif.aclk);
end
wait(vif.bvalid==1 && vif.bid==tx.id);
$display("%t: received bvalid=1 for bid=%0d",$time,tx.id);
vif.bready=1;
@(posedge vif.aclk);
vif.bready=0;
endtask

task read_addr(axi_tx tx);
@(posedge vif.aclk);
vif.arid=tx.id;
$display("arid=%h",tx.id);
vif.araddr=tx.addr;
vif.arlen=tx.burst_len;
vif.arburst=tx.burst_type;
vif.arsize=tx.burst_size;
vif.arvalid=1;
wait(vif.arready==1);
@(posedge vif.aclk);
vif.arvalid=0;
vif.arid=0;
vif.araddr=0;
vif.arlen=0;
vif.arburst=0;
vif.arsize=0;
endtask
task read_data(axi_tx tx);
for(int i=0;i<=tx.burst_len;i++)begin
while(vif.rvalid==0)begin
@(posedge vif.aclk);
end
@(posedge vif.aclk);
wait(vif.rvalid==1);
vif.rready=1;
end
@(posedge vif.aclk);
vif.rready=0;
endtask
endclass
