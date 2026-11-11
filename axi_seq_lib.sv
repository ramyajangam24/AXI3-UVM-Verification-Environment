class axi_base_seq extends uvm_sequence#(axi_tx);
uvm_phase phase;
`uvm_object_utils(axi_base_seq)
`NEW_OBJ
task pre_body();
phase=get_starting_phase();
if(phase!=null) begin
phase.raise_objection(this);
phase.phase_done.set_drain_time(this,100);
end
endtask
task post_body();
if(phase!=null) begin
phase.drop_objection(this);
end
endtask
endclass

class axi_wr_rd_seq extends axi_base_seq;
axi_tx tx;
`uvm_object_utils(axi_wr_rd_seq)
`NEW_OBJ
task body();
`uvm_do_with(req,{req.wr_rd==1;})
tx=new req;//shallow copy
`uvm_do_with(req,{req.wr_rd==0;req.id==tx.id;req.addr==tx.addr;req.burst_len==tx.burst_len;})
endtask
endclass

class axi_nwr_nrd_seq extends axi_base_seq;
rand bit [1:0]burst_type_t=2'b01;
axi_tx tx;
axi_tx txQ[$];
`uvm_object_utils(axi_nwr_nrd_seq)
`NEW_OBJ
int count;
task body();
uvm_resource_db#(int)::read_by_name("GLOBAL","COUNT",count,this);
repeat(count)begin
`uvm_do_with(req,{req.wr_rd==1;req.burst_type==burst_type_t;!(req.id inside {used_id_list});})//same sequence to support for wrap also
tx=new req;
txQ.push_back(tx);
used_id_list.push_back(tx.id);
end
repeat(count)begin
tx=txQ.pop_front();
`uvm_do_with(req,{req.wr_rd==0;req.id==tx.id;req.addr==tx.addr;req.burst_len==tx.burst_len;req.burst_type==tx.burst_type;})
end
endtask
endclass
