# 
#  Copyright 2006 - 2010 Unified EFI, Inc.<BR> 
#  Copyright (c) 2010, Intel Corporation. All rights reserved.<BR>
# 
#  This program and the accompanying materials
#  are licensed and made available under the terms and conditions of the BSD License
#  which accompanies this distribution.  The full text of the license may be found at 
#  http://opensource.org/licenses/bsd-license.php
# 
#  THE PROGRAM IS DISTRIBUTED UNDER THE BSD LICENSE ON AN "AS IS" BASIS,
#  WITHOUT WARRANTIES OR REPRESENTATIONS OF ANY KIND, EITHER EXPRESS OR IMPLIED.
# 
################################################################################
CaseLevel         FUNCTION
CaseAttribute     AUTO
CaseVerboseLevel  DEFAULT
set reportfile    report.csv

#
# test case Name, category, description, GUID...
#
CaseGuid        CF28C002-C502-4cfa-8F41-6D4BD1A11ACE
CaseName        ReadFile.Func6.Case2
CaseCategory    MTFTP4
CaseDescription {This case is to test the Function of Mtftp4.ReadFile, Server  \
                 response the Data with some packets' retransmission.}
################################################################################

proc CleanUpEutEnvironment {} {

#
# DelEntryInArpCache
#
  DelEntryInArpCache
  
  Mtftp4ServiceBinding->DestroyChild {@R_Handle1, &@R_Status}
  GetAck

  EndCapture
  EndScope _MTFTP4_READFILE_FUNCTION6_CASE2_
  EndLog
}

#
# Begin log ...
#
BeginLog

Include MTFTP4/include/Mtftp4.inc.tcl

BeginScope _MTFTP4_READFILE_FUNCTION6_CASE2_

UINTN                            R_Status
UINTN                            R_Handle1
EFI_MTFTP4_CONFIG_DATA           R_MtftpConfigData

UINTN                            R_Context
EFI_MTFTP4_TOKEN                 R_Token

CHAR8                            R_NameOfFile(20)
EFI_MTFTP4_OPTION                R_OptionList(8)
CHAR8                            R_OptionStr0(10)
CHAR8                            R_ValueStr0(10)
CHAR8                            R_OptionStr1(10)
CHAR8                            R_ValueStr1(10)
CHAR8                            R_OptionStr2(10)
CHAR8                            R_ValueStr2(10)
CHAR8                            R_ModeStr(8)

#
# Add an entry in ARP cache.
#
AddEntryInArpCache

#
# Mtftp4
#
LocalEther          [GetHostMac]
RemoteEther         [GetTargetMac]
LocalIp             192.168.88.1
RemoteIp            192.168.88.88

Mtftp4ServiceBinding->CreateChild "&@R_Handle1, &@R_Status"
GetAck
SetVar     [subst $ENTS_CUR_CHILD]  @R_Handle1
set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mtftp4SBP.CreateChild - Create Child 1"                       \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_MtftpConfigData.UseDefaultSetting   FALSE
SetIpv4Address R_MtftpConfigData.StationIp   "192.168.88.88"
SetIpv4Address R_MtftpConfigData.SubnetMask  "255.255.255.0"
SetVar R_MtftpConfigData.LocalPort           2048
SetIpv4Address R_MtftpConfigData.GatewayIp   "0.0.0.0"
SetIpv4Address R_MtftpConfigData.ServerIp    "192.168.88.1"
SetVar R_MtftpConfigData.InitialServerPort   69
SetVar R_MtftpConfigData.TryCount            10
SetVar R_MtftpConfigData.TimeoutValue        2

Mtftp4->Configure {&@R_MtftpConfigData, &@R_Status}
GetAck

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $GenericAssertionGuid                                  \
                "Mtftp4.Configure - Normal operation."                         \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

SetVar R_NameOfFile               "TestFile"
SetVar R_ModeStr                  "octet"

SetVar R_OptionStr0               "multicast"
SetVar R_ValueStr0                ""
SetVar R_OptionList(0).OptionStr  &@R_OptionStr0
SetVar R_OptionList(0).ValueStr   &@R_ValueStr0
SetVar R_OptionStr1               "timeout"
SetVar R_ValueStr1                "2"
SetVar R_OptionList(1).OptionStr  &@R_OptionStr1
SetVar R_OptionList(1).ValueStr   &@R_ValueStr1
SetVar R_OptionStr2               "blksize"
SetVar R_ValueStr2                "1024"
SetVar R_OptionList(2).OptionStr  &@R_OptionStr2
SetVar R_OptionList(2).ValueStr   &@R_ValueStr2

SetVar R_Token.OverrideData       0
SetVar R_Token.ModeStr            &@R_ModeStr
SetVar R_Token.Filename           &@R_NameOfFile
SetVar R_Token.OptionCount        3
SetVar R_Token.OptionList         &@R_OptionList
SetVar R_Token.BufferSize         0
SetVar R_Token.Buffer             0
SetVar R_Token.Context            NULL

set L_Filter "udp and src host 192.168.88.88"
StartCapture CCB $L_Filter

Mtftp4->ReadFile {&@R_Token, 1, 1, 1, &@R_Status}

ReceiveCcbPacket CCB TempPacket1 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# If have captured the packet. Server response the Data with some packets'     
# retransmission.
# Need to set the option array as the following:
# set option_value_array(blksize) "1024"
# set option_value_len(blksize) 4
#
DumpPacket TempPacket1
set client_prt [ Mtftp4GetSrcPort TempPacket1 ]

set option_value_array(multicast) "234.5.6.7,1234,1"
set option_value_len(multicast) 16

set option_value_array(timeout) "2"
set option_value_len(timeout) 1

set option_value_array(blksize) "1024"
set option_value_len(blksize) 4

SendPacket [ Mtftp4CreateOack $client_prt $EFI_MTFTP4_OPCODE_OACK]

RemoteIp            234.5.6.7
RemoteEther         01:00:5e:05:06:07

#
# Capture ack and response with data packet. the sequence of the block number  
# is 1 3. The 2 get lost.
#
ReceiveCcbPacket CCB TempPacket2 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket2 0 

SendPacket [ Mtftp4CreateData 1234 $EFI_MTFTP4_OPCODE_DATA 1 1024]

ReceiveCcbPacket CCB TempPacket3 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number. 
#
ValidateAck TempPacket3 1 

#
# wait for the timeout of the client
#
ReceiveCcbPacket CCB TempPacket4 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket4 1 

ReceiveCcbPacket CCB TempPacket5 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket5 1 

ReceiveCcbPacket CCB TempPacket6 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket6 1 

SendPacket [ Mtftp4CreateData 1234 $EFI_MTFTP4_OPCODE_DATA 2 1024] 
ReceiveCcbPacket CCB TempPacket7 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."
  
  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket7 2 

SendPacket [ Mtftp4CreateData 1234 $EFI_MTFTP4_OPCODE_DATA 3 100]

ReceiveCcbPacket CCB TempPacket8 20
if { ${CCB.received} == 0 } {

#
# If have not captured the packet. Fail
#
  GetAck
  GetVar R_Status
  set assert fail
  RecordAssertion $assert $GenericAssertionGuid                                \
                  "Mtftp4.ReadFile - It should transfer a packet, but not."

  CleanUpEutEnvironment
  return
}

#
# the second parameter indicates the block number.
#
ValidateAck TempPacket8 3 

GetAck

set assert [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion $assert $Mtftp4ReadFileFuncAssertionGuid011                    \
                "Mtftp4.ReadFile - Server responses the Data after some packets'\
                 retransmission."                                              \
                "ReturnStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

CleanUpEutEnvironment

