
# AXI3 UVM Verification Environment

A SystemVerilog/UVM testbench that drives, monitors, checks and measures coverage on an AXI3-style
master/slave interface. The environment contains an active **master agent** (driver + sequencer), a
behavioural **slave responder** with its own memory model, a **passive monitor**, a **scoreboard**,
a **functional coverage collector** and **SVA protocol assertions**. It targets **Synopsys VCS** (with
Verdi/FSDB dumping and URG coverage merging).

---

## Table of contents

1. [Features](#features)
2. [Architecture](#architecture)
3. [Interface signals](#interface-signals)
4. [File overview](#file-overview)
5. [Tests and sequences](#tests-and-sequences)
6. [Prerequisites](#prerequisites)
7. [Directory layout](#directory-layout)
8. [Build and run](#build-and-run)
9. [Coverage](#coverage)
10. [Pass / fail criteria](#pass--fail-criteria)
11. [Known limitations and TODOs](#known-limitations-and-todos)

---

## Features

- Constrained-random AXI transactions (`axi_tx`) with `INCR`, `FIXED` and `WRAP` burst types.
- WRAP address handling: lower/upper wrap boundaries are computed in `post_randomize()` and the
  address is rolled over per beat via `update_addr_for_next_beat()`.
- Master driver for all five AXI channels (AW, W, B, AR, R) with outstanding-transaction support
  through `fork ... join_none` and a semaphore that serialises the write-data channel.
- Slave responder with a byte-addressable associative-array memory, random write-response delay
  (1-30 cycles) and burst read-data generation.
- Byte-accurate scoreboard: write data is stored per byte, read data is compared against it.
- Functional coverage on address, direction, burst type, burst size and response, plus an
  address x direction cross.
- SVA handshake assertions on AW, W and B channels.
- Unique-ID write/read test (`axi_nwr_nrd_test`) and a WRAP burst test (`axi_wrap_test`).
- Code coverage (line, cond, toggle, FSM, assert, branch) wired into the run script.

---

## Architecture

```
                         ┌──────────────────────────── axi_env ────────────────────────────┐
                         │                                                                  │
  axi_base_test ───────► │  axi_master_agent            axi_slave_agent                     │
  (test_lib.sv)          │   ├─ axi_sqr  (uvm_sequencer) └─ axi_responder  (slave model)    │
        │                │   └─ axi_drv  ──────┐              ▲                             │
        ▼                │                     │              │                             │
  axi_*_seq              │                     ▼              │                             │
  (axi_seq_lib.sv)       │              ┌────────────── axi_intrf (pif) ─────────────┐      │
                         │              └───────────────────────┬────────────────────┘      │
                         │                                       │ (sampled)                 │
                         │                                  axi_mon                         │
                         │                           ap_port │        │                      │
                         │                                   ▼        ▼                      │
                         │                              axi_sbd    axi_cov                   │
                         └──────────────────────────────────────────────────────────────────┘

  top_tb: clock/reset generation, interface instance, axi_assertion bound to the same interface,
          virtual interface published through uvm_resource_db (scope "GLOBAL", name "VIF").
```

Key points:

- The virtual interface is shared through **`uvm_resource_db#(virtual axi_intrf)`** (`"GLOBAL"`, `"VIF"`).
- The monitor broadcasts completed `axi_tx` objects on `ap_port`, which feeds both the scoreboard
  and the coverage collector.
- Sequences use a second resource, `uvm_resource_db#(int)` (`"GLOBAL"`, `"COUNT"`), to know how many
  write/read pairs to issue.
- Clocking blocks in the interface separate the roles: `drv_cb`, `mon_cb` and `responder_cb`.

---

## Interface signals

`axi_intrf` is parameterised by hard-coded widths:

| Channel | Signals |
|---|---|
| Write address (AW) | `awid[3:0]`, `awaddr[31:0]`, `awlen[3:0]`, `awsize[2:0]`, `awburst[1:0]`, `awlock[1:0]`, `awvalid`, `awready` |
| Write data (W) | `wid[3:0]`, `wdata[31:0]`, `wstrb[3:0]`, `wlast`, `wvalid`, `wready` |
| Write response (B) | `bid[3:0]`, `bresp[1:0]`, `bvalid`, `bready` |
| Read address (AR) | `arid[3:0]`, `araddr[31:0]`, `arlen[3:0]`, `arsize[2:0]`, `arburst[1:0]`, `arlock[1:0]`, `arvalid`, `arready` |
| Read data (R) | `rid[3:0]`, `rdata[31:0]`, `rresp[1:0]`, `rlast`, `rvalid`, `rready` |

Burst length is 4 bits (max 16 beats, AXI3), data bus is 32 bits, ID is 4 bits (16 IDs).

---

## File overview

| File | Purpose |
|---|---|
| `top_tb.sv` | Top module: includes all TB files, generates clock/reset, instantiates interface and assertions, calls `run_test`, dumps FSDB. |
| `axi_common.sv` | `NEW_COMP` / `NEW_OBJ` constructor macros and global counters (`match_count`, `mismatch_count`, `total_beat_count`, `used_id_list`). |
| `axi_intrf.sv` | AXI interface with the signals above and the three clocking blocks. |
| `axi_tx.sv` | `axi_tx` sequence item: fields, constraints, WRAP boundary calculation, next-beat address update. |
| `axi_sqr.sv` | `typedef uvm_sequencer #(axi_tx) axi_sqr;` |
| `axi_seq_lib.sv` | Sequences: `axi_base_seq`, `axi_wr_rd_seq`, `axi_nwr_nrd_seq`. |
| `axi_drv.sv` | Master driver: write address/data/response and read address/data tasks. |
| `axi_master_agent.sv` | Wraps driver and sequencer. |
| `axi_responder.sv` | Slave BFM with memory model, write-response and read-data generation. |
| `axi_slave_agent.sv` | Wraps the responder. |
| `axi_mon.sv` | Monitor that reconstructs write/read transactions and publishes them. |
| `axi_mon_adv.sv` | **Not compiled.** Experimental ID-indexed monitor intended for out-of-order/outstanding traffic (work in progress). |
| `axi_sbd.sv` | Scoreboard (`uvm_subscriber`): byte memory model, read-vs-write data compare. |
| `axi_cov.sv` | Functional coverage collector (`uvm_subscriber`). |
| `axi_assertion.sv` | SVA handshake checks on the interface. |
| `axi_env.sv` | Environment: builds agents, monitor, scoreboard, coverage; connects analysis ports. |
| `test_lib.sv` | Tests: `axi_base_test`, `axi_wr_rd_test`, `axi_nwr_nrd_test`, `axi_wrap_test`. |
| `run.sh` | VCS compile, simulate and URG coverage-merge script. |

---

## Tests and sequences

### Sequences (`axi_seq_lib.sv`)

| Sequence | Behaviour |
|---|---|
| `axi_base_seq` | Raises/drops an objection (with 100-unit drain time) around the sequence body. |
| `axi_wr_rd_seq` | One random write followed by a read with the same ID, address and length. |
| `axi_nwr_nrd_seq` | Reads `COUNT` from the resource DB; issues `COUNT` writes with **unique IDs** (tracked in `used_id_list`), then `COUNT` reads that mirror the writes (ID, address, length, burst type). The burst type is controlled by the `burst_type_t` field (default `INCR`), so the same sequence covers WRAP. |

### Tests (`test_lib.sv`)

| Test | Description |
|---|---|
| `axi_base_test` | Builds the env, prints the topology, runs `axi_base_seq`, reports pass/fail in `report()`. |
| `axi_wr_rd_test` | Single write + read (`axi_wr_rd_seq`). |
| `axi_nwr_nrd_test` | 2 writes followed by 2 reads (`COUNT = 2`), INCR bursts. This is the default test hard-coded in `top_tb.sv`. |
| `axi_wrap_test` | Same as above but randomises the sequence with `burst_type_t == 2'b10` (WRAP) and uses a longer drain time (600). |

The test can be selected at run time with `+UVM_TESTNAME=<test>`, which overrides the name passed to
`run_test()` in `top_tb.sv`.

---

## Prerequisites

- Synopsys **VCS** (with `-kdb`/Verdi for FSDB dumping)
- Synopsys **URG** for coverage reports
- A UVM library with its DPI source, referenced in `run.sh` as
  `/home/projects/src/dpi/uvm_dpi.cc` (adjust the paths to your install)

---

## Directory layout

`run.sh` expects the following include directories relative to the run directory:

```
../top      # top_tb.sv
../master   # axi_master_agent.sv, axi_drv.sv, axi_sqr.sv, axi_seq_lib.sv
../slave    # axi_slave_agent.sv, axi_responder.sv
../common   # axi_common.sv, axi_intrf.sv, axi_tx.sv, axi_mon.sv, axi_sbd.sv,
            # axi_cov.sv, axi_env.sv, axi_assertion.sv, test_lib.sv
```

The exact split of files between `common`, `master` and `slave` is up to you, as long as every
`` `include `` in `top_tb.sv` resolves through one of the `+incdir+` paths. Run simulations from a
separate working directory (for example `sim/`) next to these folders.

---

## Build and run

The provided `run.sh` performs three steps:

```bash
# 1. Compile + elaborate (with code coverage instrumentation)
vcs -full64 -sverilog -debug_access+all -kdb -l comp.log \
    +incdir+../top +incdir+../master +incdir+../slave +incdir+../common \
    +incdir+/home/projects/src \
    /home/projects/src/dpi/uvm_dpi.cc -CFLAGS -DVCS \
    -cm line+cond+tgl+fsm+assert+branch -cm_dir compile.vdb \
    ../top/top_tb.sv

# 2. Simulate a test
./simv -l sim.log +UVM_TESTNAME=axi_wrap_test \
    -cm line+cond+tgl+fsm+assert+branch -cm_dir axi_wrap_test \
    +ntb_random_seed=480430

# 3. Merge coverage databases
urg -full64 -dir compile.vdb -dir axi_wrap_test.vdb -format both -dbname merged_coverage
```

Run a different test by changing `+UVM_TESTNAME` and the `-cm_dir` name:

```bash
./simv -l sim.log +UVM_TESTNAME=axi_nwr_nrd_test -cm line+cond+tgl+fsm+assert+branch \
       -cm_dir axi_nwr_nrd_test +ntb_random_seed=1
```

Outputs: `comp.log`, `sim.log`, `axi.fsdb` (open with Verdi), `merged_coverage/` (HTML and text reports).

> **Note:** in the current `run.sh` the `simv` command ends with `&`, so it runs in the background and
> `urg` may start before the simulation has finished writing its coverage database. Remove the `&`
> (or add a `wait`) before relying on the merged report.

---

## Coverage

**Functional** (`axi_cov.sv`, `axi_cg`):

- `ADDR_CP` (auto bins, max 8), `WR_RD_CP`, `BURST_TYPE_CP`, `RESP_CP`, `BURST_SIZE_CP`
- Cross: `ADDR_X_WR_RD_CP`
- Placeholder comment for `cache` / `prot` coverage.

**Assertions** (`axi_assertion.sv`):

| Label | Check |
|---|---|
| `WR_CHANNEL_PROP` | `awvalid` is followed by `awready` within 0-3 cycles |
| `WD_CHANNEL_PROP` | `wvalid` is followed by `wready` within 0-3 cycles |
| `WD_RESP_PROP` | `wvalid` is followed by `bvalid` within 0-30 cycles |

**Code coverage**: line, condition, toggle, FSM, assertion and branch, enabled through the `-cm` options.

---

## Pass / fail criteria

`axi_base_test::report()` prints `STATUS ... test passed` when

```
match_count == total_beat_count  &&  mismatch_count == 0
```

otherwise a `uvm_error` is raised. `total_beat_count` is accumulated in `axi_tx::post_randomize()` for
**read** transactions only (`burst_len + 1` beats per read), and the scoreboard increments
`match_count` / `mismatch_count` per read beat.

---

