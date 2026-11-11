class axi_slave_agent extends uvm_agent;
axi_responder responder;
//axi_mon mon;
`uvm_component_utils(axi_slave_agent)
function new(string name,uvm_component parent);
super.new(name,parent);
endfunction
function void build();
responder=axi_responder::type_id::create("responder",this);
//mon=axi_mon::type_id::create("mon",this);
endfunction
endclass
