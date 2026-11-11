class axi_base_test extends uvm_test;
axi_env env;
`uvm_component_utils(axi_base_test)//adding the definition of axi_base_test to the factory
`NEW_COMP
function void build();
env=axi_env::type_id::create("env",this);
endfunction
function void end_of_elaboration();
  uvm_top.print_topology();
endfunction 
function void report();
if(match_count==total_beat_count && mismatch_count==0)begin
`uvm_info("STATUS",$psprintf("%s test passed,match_count=%0d,mismatch_count=%0d",get_type_name(),match_count,mismatch_count),UVM_NONE)
end
else begin
`uvm_error("STATUS",$psprintf("%s test failed,match count=%0d,mismatch_count=%0d total_beat_count=%0d",get_type_name,match_count,mismatch_count,total_beat_count))
end
endfunction
//map the axiwr_rd_seq to the testcase
task run_phase(uvm_phase phase);
axi_base_seq base_seq;
base_seq=axi_base_seq::type_id::create("base_seq");
phase.raise_objection(this);
phase.phase_done.set_drain_time(this,100);
base_seq.start(env.magent.sqr);
phase.drop_objection(this);
endtask
endclass

class axi_wr_rd_test extends axi_base_test;
`uvm_component_utils(axi_wr_rd_test)
`NEW_COMP
task run_phase(uvm_phase phase);
axi_wr_rd_seq wr_rd_seq;
wr_rd_seq=axi_wr_rd_seq::type_id::create("wr_rd_seq");
phase.raise_objection(this);
phase.phase_done.set_drain_time(this,100);
wr_rd_seq.start(env.magent.sqr);
phase.drop_objection(this);
endtask
endclass

class axi_nwr_nrd_test extends axi_base_test;
`uvm_component_utils(axi_nwr_nrd_test)
`NEW_COMP
function void build();
super.build();
uvm_resource_db#(int)::set("GLOBAL","COUNT",2,this);
endfunction

task run_phase(uvm_phase phase);
axi_nwr_nrd_seq nwr_nrd_seq;
nwr_nrd_seq=axi_nwr_nrd_seq::type_id::create("nwr_nrd_seq");
phase.raise_objection(this);
phase.phase_done.set_drain_time(this,100);
nwr_nrd_seq.start(env.magent.sqr);
phase.drop_objection(this);
endtask
endclass

class axi_wrap_test extends axi_base_test;
`uvm_component_utils(axi_wrap_test)
`NEW_COMP
rand bit [1:0]burst_type_t=2'b01;
function void build();
super.build();
uvm_resource_db#(int)::set("GLOBAL","COUNT",2,this);
endfunction

task run_phase(uvm_phase phase);
axi_nwr_nrd_seq nwr_nrd_seq;
nwr_nrd_seq=axi_nwr_nrd_seq::type_id::create("nwr_nrd_seq");
nwr_nrd_seq.randomize() with {burst_type_t ==2'b10;};
phase.raise_objection(this);
phase.phase_done.set_drain_time(this,600);
nwr_nrd_seq.start(env.magent.sqr);
phase.drop_objection(this);
endtask
endclass

