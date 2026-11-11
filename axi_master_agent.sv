class axi_master_agent extends uvm_agent;
axi_drv drv;
axi_sqr sqr;

`uvm_component_utils(axi_master_agent)
function new(string name,uvm_component parent);
super.new(name,parent);
endfunction
function void build();
drv=axi_drv::type_id::create("drv",this);
sqr=axi_sqr::type_id::create("sqr",this);
endfunction
function void connect();
drv.seq_item_port.connect(sqr.seq_item_export);
endfunction
endclass
