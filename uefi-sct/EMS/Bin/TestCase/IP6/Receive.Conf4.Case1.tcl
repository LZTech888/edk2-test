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
CaseLevel          CONFORMANCE
CaseAttribute      AUTO
CaseVerboseLevel   DEFAULT
set reportfile     report.csv

#
# Test Case Name, Category, Description, GUID ...
#
CaseGuid           306F63E7-E4A6-4bae-B926-830E74DE6DDC
CaseName           Receive.Conf4.Case1
CaseCategory       IP6
CaseDescription    {Test the Receive Function of IP6 - invoke Receive()  \
                    when Token.Event is already in the receive queue. EFI_ACCESS_DENIED should be returned
                   }
################################################################################

Include IP6/include/Ip6.inc.tcl

#
# Begin  log ...
#
BeginLog
#
# Begin Scope ...
#
BeginScope         IP6_RECEIVE_CONF4_CASE1_

# Parameter Definition
# R_ represents "Remote EFI Side Parameter"
# L_ represents "Local OS Side Parameter"
#
UINTN                       R_Status
UINTN                       R_Handle 

#
# Create Child
#
Ip6ServiceBinding->CreateChild "&@R_Handle, &@R_Status"
GetAck
set assert       [VerifyReturnStatus R_Status $EFI_SUCCESS]
RecordAssertion  $assert $GenericAssertionGuid               \
                 "Ip6SB->CreateChild - Conf - Create Child "             \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"
SetVar  [subst $ENTS_CUR_CHILD]    @R_Handle

EFI_IP6_CONFIG_DATA                R_Ip6ConfigData
SetVar           R_Ip6ConfigData.DefaultProtocol    0x11;       #NextHeader: UDP
SetVar           R_Ip6ConfigData.AcceptAnyProtocol  FALSE
SetVar           R_Ip6ConfigData.AcceptIcmpErrors   TRUE
SetVar           R_Ip6ConfigData.AcceptPromiscuous  FALSE
SetIpv6Address   R_Ip6ConfigData.DestinationAddress "::"
SetIpv6Address   R_Ip6ConfigData.StationAddress     "::"
SetVar           R_Ip6ConfigData.TrafficClass       0
SetVar           R_Ip6ConfigData.HopLimit           64
SetVar           R_Ip6ConfigData.FlowLabel          0
SetVar           R_Ip6ConfigData.ReceiveTimeout     50000
SetVar           R_Ip6ConfigData.TransmitTimeout    50000

#
# Configure the Child with valid parameter
#
Ip6->Configure   "&@R_Ip6ConfigData, &@R_Status"
GetAck
set  assert      [VerifyReturnStatus    R_Status    $EFI_SUCCESS]
RecordAssertion  $assert        $GenericAssertionGuid              \
                 "Ip6->Configure -Conf- Configure the Child with Valid parameter "   \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

EFI_IP6_COMPLETION_TOKEN                            R_Token
UINTN            R_NotifyContext                     
SetVar           R_NotifyContext                     0

#
# Create an Event
#
BS->CreateEvent  "$EVT_NOTIFY_SIGNAL, $EFI_TPL_CALLBACK, 1, &@R_NotifyContext, &@R_Token.Event, &@R_Status"
GetAck
set assert        [VerifyReturnStatus  R_Status  $EFI_SUCCESS]
RecordAssertion   $assert      $GenericAssertionGuid            \
                  "BS->CreateEvent -Conf- Create an Event  "              \
                  "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

#
# Check point:Call Receive Function when Token->Event has already been queued.EFI_ACCESS_DENIED should be returned.
#    
Ip6->Receive    "&@R_Token, &@R_Status"
GetAck
set  assert      [VerifyReturnStatus R_Status  $EFI_SUCCESS]
RecordAssertion  $assert       $GenericAssertionGuid                  \
                 "Ip6->Receive -Conf- Call Receive  Function with valid parameter "     \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

#
# Call Receive Function again with the same Event
#
Ip6->Receive     "&@R_Token, &@R_Status"
GetAck
set  assert      [VerifyReturnStatus   R_Status  $EFI_ACCESS_DENIED]
RecordAssertion  $assert        $Ip6ReceiveConf4AssertionGuid001       \
                 "Ip6->Receive -Conf- Call Receive function with the same event again"   \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_ACCESS_DENIED"

#
# Destroy Child
#
Ip6ServiceBinding->DestroyChild {@R_Handle, &@R_Status}
GetAck
set assert        [VerifyReturnStatus  R_Status $EFI_SUCCESS]
RecordAssertion   $assert  $GenericAssertionGuid                 \
                  "Ip6SB->DestroyChild - Conf - Destroy Child"              \
                  "RetrunStatus - $R_Status, ExpectedStatus - $EFI_SUCCESS"

#
# Close an Event
#
BS->CloseEvent    "@R_Token.Event, &@R_Status"
GetAck
set assert       [VerifyReturnStatus  R_Status  $EFI_SUCCESS]
RecordAssertion  $assert       $GenericAssertionGuid         \
                 "BS->CloseEvent -Conf- Close the Event "              \
                 "ReturnStatus -$R_Status, ExpectedStatus -$EFI_SUCCESS"

#
# End scope
#
EndScope         IP6_RECEIVE_CONF4_CASE1_
#
# End log
#
EndLog
