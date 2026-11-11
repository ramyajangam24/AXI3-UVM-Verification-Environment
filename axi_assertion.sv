module axi_assertion(axi_intrf pif);
property write_addr_hndshk_prop;
@(posedge pif.aclk) pif.awvalid==1 |->##[0:3]pif.awready==1;
endproperty
WR_CHANNEL_PROP:assert property(write_addr_hndshk_prop);
property write_data_hndshk_prop;
@(posedge pif.aclk) pif.wvalid==1|->##[0:3]pif.wready==1;
endproperty
WD_CHANNEL_PROP:assert property(write_data_hndshk_prop);
property write_resp_hndshk_prop;
@(posedge pif.aclk) pif.wvalid==1|->##[0:30]pif.bvalid==1;
endproperty
WD_RESP_PROP:assert property(write_resp_hndshk_prop);
endmodule
