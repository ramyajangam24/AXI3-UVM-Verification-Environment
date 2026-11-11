`define NEW_COMP\
function new(string name,uvm_component parent);\
super.new(name,parent);\
endfunction
`define NEW_OBJ\
function new(string name="");\
super.new(name);\
endfunction
int match_count;
int mismatch_count;
int total_beat_count;//0 default value of int is 0
bit [3:0]used_id_list[$];
