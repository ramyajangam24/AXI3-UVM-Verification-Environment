class axi_responder extends uvm_component;
bit [7:0]mem[*];
semaphore smp_wr=new(1);
`uvm_component_utils(axi_responder)
`NEW_COMP
axi_tx wrtxA[15:0];
axi_tx rdtxA[15:0];
virtual axi_intrf vif;
bit [31:0]awaddr_t;
bit [3:0]awlen_t;
bit [2:0]awsize_t;
bit [1:0]awburst_t;
bit [31:0]wdata_t;
//read_signals 
bit [31:0]araddr_t;
bit [3:0]arid_t;
bit [3:0]arlen_t;
bit [2:0]arsize_t;
bit [1:0]arburst_t;
bit [31:0]rdata_t;
byte mem[*];//associative array
byte byteQ[$];//queue,fifo
function void build_phase(uvm_phase phase);
super.build_phase(phase);
uvm_resource_db#(virtual axi_intrf)::read_by_name("GLOBAL","VIF",vif,this);
endfunction
task run();
string name;
forever begin
@(vif.responder_cb);
 if(vif.responder_cb.awvalid==1)begin
    vif.responder_cb.awready<=1;//this component (~slave)will capture the write assress information
    name=$psprintf("wrtx%0d",vif.responder_cb.awid);
    wrtxA[vif.responder_cb.awid]=new(name);
    wrtxA[vif.responder_cb.awid].id=vif.responder_cb.awid;
    wrtxA[vif.responder_cb.awid].addr=vif.responder_cb.awaddr;
    wrtxA[vif.responder_cb.awid].burst_len=vif.responder_cb.awlen;
    wrtxA[vif.responder_cb.awid].burst_size=vif.responder_cb.awsize;
    wrtxA[vif.responder_cb.awid].burst_type=vif.responder_cb.awburst;
 end
 else begin
    vif.responder_cb.awready<=0;
 end
if(vif.responder_cb.arvalid==1)begin
      vif.responder_cb.arready<=1;//this component (~slave)will capture the write assress information
      name=$psprintf("rdtx%0d",vif.responder_cb.arid);
      rdtxA[vif.responder_cb.arid]=new(name);
      rdtxA[vif.responder_cb.arid].id=vif.responder_cb.arid;
      rdtxA[vif.responder_cb.arid].addr=vif.responder_cb.araddr;
      rdtxA[vif.responder_cb.arid].burst_len=vif.responder_cb.arlen;
      rdtxA[vif.responder_cb.arid].burst_size=vif.responder_cb.arsize;
      rdtxA[vif.responder_cb.arid].burst_type=vif.responder_cb.arburst;
      fork//it is triggering process & proceeding further not waiting to complete,it will not block
      read_data(vif.responder_cb.arid);//this is not complete data
      join_none
   end
   else begin
      vif.responder_cb.arready<=0;
  end

if(vif.responder_cb.wvalid==1)begin
   vif.responder_cb.wready<=1;
   awaddr_t=wrtxA[vif.responder_cb.wid].addr;//current beat addr
   awsize_t=wrtxA[vif.responder_cb.wid].burst_size;
   wdata_t=vif.responder_cb.wdata;
   $display("%t:writing at addr<=%h,data<=%h",$time,awaddr_t,vif.responder_cb.wdata);
   //wdata will becaptured and stored to the memory
   //if(wrap or incr)begin
	   for(int j=0;j<2**awsize_t;j++)begin
   mem[awaddr_t+j]=wdata_t[7:0];
   wdata_t>>=8;
   end
   //mem[awaddr_t+1]=vif.responder_cb.wdata[15:8];
   //mem[awaddr_t+2]=vif.responder_cb.wdata[23:16];
   //mem[awaddr_t+3]=vif.responder_cb.wdata[31:24];//lower byte going to lower next byte going to next address
   //else begin
   //        byteQ.push_back(vif.responder_cb.wdata[7:0]);
   //        byteQ.push_back(vif.responder_cb.wdata[15:8]);
   //        byteQ.push_back(vif.responder_cb.wdata[23:16]);
   //        byteQ.push_back(vif.responder_cb.wdata[31:24]);
   //end

   //awaddr_t=awaddr_t+2**awsize_t;//once transfer completes incr address 
   wrtxA[vif.responder_cb.wid].update_addr_for_next_beat();//addr for next beat
   if(vif.responder_cb.wlast==1)begin//whenever slave gets last data phase,it will initiate wr_response phase
    fork
   write_resp(vif.responder_cb.wid);
   join_none
   end
end
else begin
vif.responder_cb.wready<=0;
end
end
endtask 

task write_resp(bit [3:0]id);
int write_resp_delay;
write_resp_delay=$urandom_range(1,30);
$display("waiting for %0d clock cycles before issuing write response",write_resp_delay);
repeat(write_resp_delay)@(vif.responder_cb);
smp_wr.get(1);
@(vif.responder_cb);
vif.bid<=id;
vif.bresp<=2'b00;
vif.bvalid<=1'b1;
$display("waiting for bready=1,bid=%0d",id);
wait(vif.responder_cb.bready==1);
$display("waiting for bready=1,bid=%0d",id);
@(vif.responder_cb);
vif.bid<=0;
vif.bresp<=2'b00;
vif.bvalid<=0;
smp_wr.put(1);
endtask


  
task read_data(bit [3:0]id);
arlen_t=rdtxA[id].burst_len;
for(int i=0;i<=arlen_t;i++)begin
@(vif.responder_cb);
//as of now this code,we didn't implement memory,hence giving random data
//vif.responder_cb.rdata<=$random;//mem[vif.responder_cb.araddr]
//araddr_t<=araddr_t+2**arsize_t;
araddr_t=rdtxA[id].addr;//current beat address
arsize_t=rdtxA[id].burst_size;
for(int j=0;j<2**arsize_t;j++)begin
rdata_t[31:24]=mem[araddr_t+j];
if(j<2**arsize_t-1) rdata_t>>=8;
end
//rdata_t[7:0]=mem[araddr_t];
//rdata_t[15:8]=mem[araddr_t+1];
//rdata_t[23:16]=mem[araddr_t+2];
//rdata_t[31:24]=mem[araddr_t+3];
$display("%t:reading at addr <=%h,data<=%h",$time,araddr_t,rdata_t);
vif.responder_cb.rdata<=rdata_t;
vif.responder_cb.rid<=id;
vif.responder_cb.rvalid<=1;
vif.responder_cb.rlast<=(i==arlen_t)?1:0;
vif.responder_cb.rresp<=2'b00;

wait(vif.responder_cb.rready==1);
//araddr_t=araddr_t+2**arsize_t;
//rdtxA[id].addr+=2**arsize_t;
rdtxA[id].update_addr_for_next_beat();
end
@(vif.responder_cb);
vif.responder_cb.rdata<=0;
vif.responder_cb.rid<=0;
vif.responder_cb.rvalid<=0;
vif.responder_cb.rlast<=0;
vif.responder_cb.rresp<=0;
endtask
endclass

