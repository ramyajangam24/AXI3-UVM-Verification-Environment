class axi_tx extends uvm_sequence_item;
rand bit [31:0]addr;
rand bit [31:0]dataQ[$];
rand bit wr_rd;
rand bit [3:0]id;
rand bit [1:0]burst_type;
rand bit [3:0]burst_len;
rand bit [2:0]burst_size;
bit [1:0]resp;
rand bit [3:0]strbQ[$];
rand bit [2:0]prot;
rand bit [1:0]lock;
rand bit [3:0]cache;
bit [31:0]wrap_upper_addr;
bit [31:0]wrap_lower_addr;
`uvm_object_utils_begin(axi_tx)
`uvm_field_int(addr,UVM_ALL_ON)
`uvm_field_queue_int(dataQ,UVM_ALL_ON)
`uvm_field_int(wr_rd,UVM_ALL_ON)
`uvm_field_int(id,UVM_ALL_ON)
`uvm_field_int(burst_type,UVM_ALL_ON)
`uvm_field_int(burst_len,UVM_ALL_ON)
`uvm_field_int(burst_size,UVM_ALL_ON)
`uvm_field_int(resp,UVM_ALL_ON)
`uvm_field_queue_int(strbQ,UVM_ALL_ON)
`uvm_field_int(prot,UVM_ALL_ON)
`uvm_field_int(lock,UVM_ALL_ON)
`uvm_field_int(cache,UVM_ALL_ON)

`uvm_object_utils_end
`NEW_OBJ
function void post_randomize();
int tx_size_in_bytes;
tx_size_in_bytes=(burst_len+1)*(2**burst_size);
wrap_lower_addr=addr-(addr%tx_size_in_bytes);
wrap_upper_addr=wrap_lower_addr+tx_size_in_bytes-1;
if(wr_rd==0) total_beat_count+=burst_len+1;//comparing only reads

endfunction
function void update_addr_for_next_beat();
addr=addr+2**burst_size;
if(burst_type==2'b10&& addr>wrap_upper_addr)begin//wrap & addr reached wrap boundary
	addr=wrap_lower_addr;
end
endfunction

//constraints
constraint dataQ_c{
dataQ.size()==burst_len+1;
foreach(strbQ[i]){
soft strbQ[i]==4'b1111;
}
}
constraint soft_c{
soft burst_size==2;//4 bytes per beat(wdata[31:0])
soft burst_type==2'b01;//incr
soft addr%2**burst_size==0;//aligned
(burst_type==2'b10)->burst_len inside {1,3,7,15};
}
constraint rsvd_c{
lock!=2'b11;
burst_type!=2'b11;
}
endclass

