class axi_sbd extends uvm_subscriber#(axi_tx);
byte sbd_mem[*];
`uvm_component_utils(axi_sbd)
`NEW_COMP
axi_tx tx;
function void write(axi_tx t);
tx=new t;
if(tx.wr_rd==1)begin
//1 axi_tx consists of burst_length*burst_size
foreach(tx.dataQ[i])begin
//sbd_mem[tx.addr]=tx.dataQ[i][7:0];
//sbd_mem[tx.addr+1]=tx.dataQ[i][15:8];
//sbd_mem[tx.addr+2]=tx.dataQ[i][23:16];
//sbd_mem[tx.addr+3]=tx.dataQ[i][31:24];
for(int j=0;j<2**tx.burst_size;j++)begin
sbd_mem[tx.addr+j]=tx.dataQ[i][7:0];
tx.dataQ[i]>>=8;//upper byte comes to lower position
end
tx.addr=tx.addr+2**tx.burst_size;
//during writes stores the data to memory
end
end
else begin
foreach(tx.dataQ[i])begin
if(sbd_mem[tx.addr]==tx.dataQ[i][7:0]&&
sbd_mem[tx.addr+1]==tx.dataQ[i][15:8]&&
sbd_mem[tx.addr+2]==tx.dataQ[i][23:16]&&
sbd_mem[tx.addr+3]==tx.dataQ[i][31:24])begin
match_count++;
end
else begin
mismatch_count++;
end
tx.addr=tx.addr+2**tx.burst_size;
end
end
endfunction
endclass

