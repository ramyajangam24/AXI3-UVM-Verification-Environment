class axi_env extends uvm_env;
axi_master_agent magent;
axi_slave_agent sagent;
axi_sbd sbd;
axi_mon mon;
axi_cov cov;//wrap,incr,lock,excl
`uvm_component_utils(axi_env)
function new(string name,uvm_component parent);
super.new(name,parent);
endfunction
function void build();
mon=axi_mon::type_id::create("mon",this);
cov=axi_cov::type_id::create("cov",this);
magent=axi_master_agent::type_id::create("magent",this);
sagent=axi_slave_agent::type_id::create("sagent",this);
sbd=axi_sbd::type_id::create("axi_sbd",this);
endfunction
function void connect();
mon.ap_port.connect(sbd.analysis_export);
mon.ap_port.connect(cov.analysis_export);

endfunction
endclass

