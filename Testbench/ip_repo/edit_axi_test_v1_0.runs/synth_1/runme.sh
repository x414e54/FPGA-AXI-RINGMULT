#!/bin/sh

# 
# Vivado(TM)
# runme.sh: a Vivado-generated Runs Script for UNIX
# Copyright 1986-2016 Xilinx, Inc. All Rights Reserved.
# 

if [ -z "$PATH" ]; then
  PATH=/run/media/x414e54/Games/opt/Xilinx/SDK/2016.4/bin:/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/ids_lite/ISE/bin/lin64:/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/bin
else
  PATH=/run/media/x414e54/Games/opt/Xilinx/SDK/2016.4/bin:/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/ids_lite/ISE/bin/lin64:/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/bin:$PATH
fi
export PATH

if [ -z "$LD_LIBRARY_PATH" ]; then
  LD_LIBRARY_PATH=/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/ids_lite/ISE/lib/lin64
else
  LD_LIBRARY_PATH=/run/media/x414e54/Games/opt/Xilinx/Vivado/2016.4/ids_lite/ISE/lib/lin64:$LD_LIBRARY_PATH
fi
export LD_LIBRARY_PATH

HD_PWD='/home/x414e54/Documents/FPGA-tests/Testbench/ip_repo/edit_axi_test_v1_0.runs/synth_1'
cd "$HD_PWD"

HD_LOG=runme.log
/bin/touch $HD_LOG

ISEStep="./ISEWrap.sh"
EAStep()
{
     $ISEStep $HD_LOG "$@" >> $HD_LOG 2>&1
     if [ $? -ne 0 ]
     then
         exit
     fi
}

EAStep vivado -log axi_test_v1_0.vds -m64 -product Vivado -mode batch -messageDb vivado.pb -notrace -source axi_test_v1_0.tcl
