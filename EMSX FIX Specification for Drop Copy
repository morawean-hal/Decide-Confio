Overview
This document describes how to receive drop copy messages from EMSX using the FIX protocol. This guide is intended for business and technical professionals within Bloomberg, their clients, third-party OMS providers, and FIX vendors. Do not disclose the information in this document to any person other than the intended recipient or those involved in the integration or evaluation of the Bloomberg EMSX and EMSxNet.

Asset Types and Coverage
Equity – Global, US, EMEA, Asia/Pacific, Australia
Futures – Global, Index, Rates, and Commodity, Currency
Options – Global, Equity, and Index
Setup and Administration
FIX connections are setup and administered by the Bloomberg installation team. Broker mappings are supported on a 1-to-1 basis for each asset class. In addition, each Bloomberg broker code can be mapped to one user-defined mnemonic.

Systems Available
Drop copy enables customers to “drop” and communicate messages for these systems:

AIM
EMSX
RFQE – (Listed: Maker & Taker flow available)
SSEOMS
EMSxNet
TSOX – (Futures flow available)
Getting Started
For authentication, authorization and related information required to use FIX, see the FIX Connectivity Policy.

Message Flows
This section provides high-level details of drop copy’s supported message flows.

Flow
Description
Overall
The system drops Ack (Acknowledgement) and execution messages that are received from the brokers. It does not drop messages sent to the brokers (35=D,E,F,G).
Electronic vs. Manual
Only electronic messages communicated to brokers, RFQE, and dark pools are dropped. Manually entered routes (and subsequent fill-related activity on those routes) are not available to be sent by the drop copy system.
Parent Order
Parent orders in EMSX cannot be dropped via drop copy. Only broker routes and related messages can be dropped.
New Route
The Ack message from the broker drops via the FIX connection. This message includes route details that includes the broker code and user’s UUID. It also includes Bloomberg route ID in tag 11.
Fills
Fills are transmitted as they are received from brokers and execution venues. Fills reference the route ID that is sent in the Ack message for a new cancel and replace route message.
Busts and Corrects
Amendments and cancel messages drop via the FIX connection as they are received from the broker.
Modify Order
A successful Ack message from the broker for a cancel and replace route drops as an unsolicited modify message.
Cancel Order
A successful Ack message from the broker for a cancel request drops as an unsolicited cancel message to the recipient’s system.
Session Settings
There are a number of session-level settings that integrate with FIX-compliant Order Management Systems. Some of the key session-level settings that you can configure for an OMS staging client are shown below.

General Settings
Setting
Description
FIX Version
Supported Versions: 4.0, 4.1, and 4.2
Version Adherence
Specify to adhere to the supported protocol version values, as shown below.
Strict adherence to the specified version, and does not have tags that are not specified in the version.
Strict adherence to the specified version, and passes the broker-defined tags below 5,000 that are not specified in the version.
Strict adherence to the specified version does not pass tags that are not specified in the version; but passes broker-defined tags in the 5,000+ range.
Strict adherence to the specified version, and passes broker-defined tags that are not specified in the version. For example, near the pass through of each broker message.
Asset Type
Select one or multiple asset types, such as Equities, Futures, and Options.
Account
Enables drops from specific Bloomberg terminal accounts. If enabled and an account is not specified, all messages drop.
Note: This is a customer number for the Bloomberg terminal account.

UUID
Enables or disables drops for specific UUIDs. The setting can be turned ON for one or a list of UUIDs.
Broker Codes
Enables or disables drops for specific broker codes. The setting can be turned ON for one or a list of broker codes, or the setting can be used to exclude one or more broker codes from the drop copy executions.
Message Types
All
Fill
Bust
Ack
Calc
Done
Stop
Replace
Pending
Cancel
Reject
Account Tag
Enables you to specify a tag, if the account field should be communicated in Tag 1.
Sends Tag 1 Account – Drops Tag 1 <Account> as sent by the broker and sends the account if it is present on the route to the drop copy.

Sends Broker Account – Tag 1 <Account>, as present on the broker message, is passed through, if present.

Sends Tag 1 Account, otherwise Broker Account – The account, if present on the route, is sent to the drop copy; otherwise, tag 1 <Account> on the broker message is passed through if present in the FIX message.

Yellow Key
Enables and disables the Bloomberg yellow key in Tags 55 and 48.
Broker Code Tag
Enables you to specify the tag for the broker code.
Security Exchange
Identifies the tag that carries exchange information, such as, tag 100 and 207.
Strategy Tag
Identifies the tag that carries the algo strategy short name, as defined in the Bloomberg system.
Default Name
Linked to the Strategy Tag fields. The default name enables you to receive a default Strategy Name if there is none on the route.
3rd Party
Drop routing tags: 115, 116, 128, and 129.
This setting enables you to turn off FIX routing tags if the recipient does not want to receive them.

Prefix Tag
This setting prefixes route identifier values with the broker code to ensure unique values across multiple broker sessions.
Enables and disables prefixes: 11, 17*, 37, 41

*FIX versions 4.1 and 4.2 support Tag 17 only.

BlockID Tag
Supports the BlockID tag, if configured on the order, in the drop copy message.
InvestorID Tag
Supports the InvestorID, if provided on the order, in the drop copy message.
Order Owner UUID Tag
For E2E Brokers. It is a custom tag that provides the original order owner on the E2E electronic route. (Tag 57 uses the EMSX UUID of the E2E router.)
Originator MiFID Fields
Receives the MiFID II fields in the EMSX that are populated by the order originator in the route acknowledge message. The MiFID fields are not included on individual fill messages.
Broker MiFID Fields
Receives the MiFID II fields in the EMSX that are sent by the broker (only on individual execution messages that the broker populates), are passed through without validation or translation.
SecondaryExecID
Receives a secondary Exec ID (Tag 527), if provided by the broker in the execution reports.
Equities Settings
SettingDescriptionSecurity ID USA unique identifier of a user, account, or other security principal. Available options: CUSIP, ISIN, SEDOL, TickerSecurity ID Non-USAvailable options: CUSIP, ISIN, SEDOL, TickerSymbol SuffixEnables and disables the suffix in Tag 65. The process parses the symbol and sends the data follows to the ticker. For example, XXXX.A. The tag for this data is “A”.Security Type

Enables and disables Tag 167. The sent values are:

CS = Common Stocks
PS = PFD Stocks
WAR = Warrants
Format: Indent first line (indent left 3 times)

PreferredEnables and disables preferred drops.Commissions and FeesReceives commissions and fees fields when sent by the broker.Buy to CoverEnables Tag 77 = C for COVR orders in the EMSX.

Option Settings
Setting
Description
Security ID US
A unique identifier of a user, account, or other security principal. Available options: Root, Full
Security ID Non-US
Available options: Bloomberg, Root, Full
Symbol US
The option’s ticker symbol in the United States. Available options: Root, Full in Tag 55
Symbol Non-US
The option’s ticker symbol in countries other than the United States.
Available options: Bloomberg, Root, Full in Tag 55

ID Source
The source identification of the option.
Available options: Bloomberg (A), Exchange (8)

Covered or Uncovered
Identifies if the option is covered.
Underlying Product
The product type of the underlying instrument (Equities (5)).
Underlying Security Exchange
The exchange code for the underlying security. Communicates the Bloomberg exchange codes.
Clearing Firm
The clearing firm’s information.
Product
Identifies the Equities vs. Index option (Equities (5), Index (7)).
Maturity Day
The maturity date of the option.
Underlying Security ID
The option’s underlying Security ID and CUSIP, if available for security.
Underlying Security Type
The option’s underlying product type: Equities: CS
Clearing Account
The clearing account, if present on the route.
Security Description
The security description, if present on the route.
Underlying Symbol
The underlying ticker: Bloomberg Ticker symbol
Underlying ID Source
The underlying Security ID source, such as CUSIP.
Customer or Firm
Tag 204. Specifies if the order is for a customer or a firm.
Futures Settings
Setting
Description
Maturity Month Year
Last Trade Date (T), Expiration Month/Year (E), None (N)
Security ID
The Security ID of the future.
Available options: Ticker, None

ID Source
The source identification of the future.
Available options: Bloomberg (A), Exchange (8)

Pass Tag 100
Enables and disables the setting to forward broker-sent values.
BMF Support
Enables and disables the BMF symbol in tags 55, 48, 22, and 207.
Underlying Product
The future’s underlying product – Tag 462:
2 = COMMODITY
4 = CURRENCY
5 = EQUITY
7 = INDEX

Format: Indent first line (indent left 4 times)

Underlying Security Exchange
The exchange code for the underlying security exchange. Communicates the Bloomberg exchange codes.
Clearing Firm
The clearing firm’s information.
Product
The future’s product type: Tag 461
2 = COMMODITY
4 = CURRENCY
5 = EQUITY
7 = INDEX

Maturity Day
The maturity date of the future.
Underlying Security ID
The underlying Security ID and CUSIP, if available for security.
Underlying Security Type
The future’s underlying security type: Tag 310:
CS = Common Stock
FUT = Future
OPT = Option
PS = Preferred Stock
WAR = Warrant
MLEG = Multi-leg instrument

Format: Indent first line (indent left 6 times)

Clearing Account
The clearing account, if present on the route.
Open and Close
The opening or closing of the position identifier.
Security Description
The security description, if present in the message.
Underlying Symbol
The underlying ticker: Bloomberg Ticker symbol
Underlying ID Source
The underlying Security ID source, such as CUSIP.
Futures Spread Support
Drops the parent fill of an exchange that has been traded on the Futures Spread route.
FIX Messages
Bloomberg complies with FIX Specifications 4.0–4.2 for the standard header and message body. For information, see http://www.fixprotocol.org.

Unsolicited executions maintain the appearance of solicited Execution Reports with these exceptions:

For the initial Execution Report Tag 39=0.
The unsolicited Execution Reports cannot contain Tag 11.
Replacements cannot contain Tags 41 and 11.
Headers
The table below describes the headers in the FIX messages.

Tag
Tag Name
Red per FIX
Notes (Supplemental to FIX 4.1 and 4.2 Specifications)
8
BeginString
Y
9
BodyLength
Y
35
MsgType
Y
49
SenderCompId
Y
56
TargetCompId
Y
34
MsgSeqNum
Y
50
SenderSubId
N
57
TargetSubld
N
UUID (Unique User Identifier) for the Bloomberg user.
43
PossDupFlag
N
97
PossResend
N
52
SendingTime
Y
YYYYMMDD-HM:MI:SS
122
OrigSendingTime
N
Execution Messages
The table below contains the details of the tags expected on (35=8) Execution Report messages in addition to those specified in the header and footer.

Tag
Tag Name
EQTY
FUT
OPT
Notes (Supplemental to FIX 4.1/4.2 Specifications)
1
Account
Y
Y
Y
If the values are available on the route
55/48
BMF Support
Y
BMF futures only
6
AvgPx
Y
Broker-supplied value
11
ClOrdId
Not present for NOEs (unsolicited orders from the broker that were not generated within Bloomberg)
12
Commission
Y
Y
Y
Broker-supplied value
13
CommType
Y
Y
Y
Broker-supplied value
14
CumQty
Y
Bloomberg normally calculates based on fills received from the broker. For cancel/replace requests, bust, and corrects, Bloomberg resets or calculates the value to match the value sent by the broker.
15
Currency
Y
Y
Y
Bloomberg provides the broker-supplied value.
17
ExecId
Y
Y
Y
Unique per order date (Tag 75) and over the life of the GTC route. Max Length: 40 characters
18
ExecInst
N
N
N
19
ExecRefId
Y
Y
Y
Max Length: 40 characters
20
ExecTransType
Y
Y
Y
Tag 19 is present if 20=1 or 20=2.
21
HandlInst
Y
Y
Y
Route-based value
22
IdSource
8, A
8, A, J
29
LastCapacity
Y
Broker-supplied value
30
LastMkt
Y
Broker-supplied value. Bloomberg encourages and recommends brokers communicate the MIC. Max Length: 7 characters
31
LastPx
Y
Y
Y
Broker-supplied value
32
LastShares
Y
Y
Y
Broker-supplied value
37
OrderId
Y
Bloomberg Route ID, Max Length: 40 characters
38
OrderQty
Y
Y
Y
Bloomberg sends the broker value in replaced messages (Tag 39=5).
39
OrdStatus
Not supported
40
OrdType
Y
Y
Y
Route order type
41
OrigClOrdId
Y
Y
Y
Bloomberg sends this for cancel/replace messages
44
Price
Y
Y
Y
Price instructions on the route
48
SecurityId US
CUSIP
ISIN
Sedol
Ticker
OSI
48
SecurityId Non-US
ISIN
Sedol
Ticker
Bloomberg
54
Side
Y
Y
Y
55
Symbol US
Ticker
Bloomberg
OSI
55
Symbol Non-US
Ticker
Bloomberg
Bloomberg
58
Text
Y
Y
Y
Broker-supplied value, Max Length: 180 characters
59
TimeInForce
Y
Y
Y
Route TI
60
TransactTime
Y
Y
Broker-supplied transaction time
65
Symbol Suffix
Y
76
ExecBroker
Y
Y
Max Length: 5 characters
77
OpenClose
Y
Y
Y
99
StopPx
Y
Price instruction on the route
107
SecurityDesc
Y
Y
109
ClientId
Client ID setup on FNAB
126
ExpireTime
N
N
N
136
NoMiscFees
Y
Y
Y
Broker-supplied fees
137
MiscFeeAmt
138
MiscFeeCurr
139
MiscFeeType
150
ExecType
Y
Y
Y
Unsupported FIX 4.2 value: D
Not supported for FIX 4.0

167
SecurityType
Y
Y
Y
200
MaturityMonthYear
T-Last Trade Date
E-Expiration

MonthYear

None

‘E’: Only tag 200 <MaturityDate> sent as YYYYMM tag 205 <MaturityDay>, if present, is dropped. ‘T’: Last trade date sent in tags 200/205 ‘N’: Tags 200/205 sent
202
StrikePrice
Y
Not sent for Opt or Fut.
203
CoveredOrUncovered
Y
204
CustomerOrFirm
205
MaturityDay
Y
Y
207
SecurityExchange
Tags 207 and 55
Tags 207 and 55
(SSF)

Tag 207
Bloomberg exchange codes
305
UnderlyingIDSource
Y
Y
308
UnderlyingSecurityExchange
Y
Y
309
UnderlyingSecurityID
Y
Y
310
UnderlyingSecurityType
Y
Y
311
UnderlyingSymbol
Y
Y
439
ClearingFirm
Y
Y
440
ClearingAccount
Y
Y
460
Product
Y
Y
462
UnderlyingProduct
Y
Y
453
NoPartyIDs
Y
Y
Y
Number of PartyID: 448
PartyIDSource: 447

PartyRole: 452 entries

448
PartyID
Y
Y
Y
447
PartyIDSource
Y
Y
Y
452
PartyRole
Y
Y
Y
527
Secondary ExecID
Y
Y
Y
775
Booking Type
Y
828
TrdType
Y
Y
Y
829
TrdSubType
Y
Y
Y
855
SecondaryTrdType
Y
Y
Y
2524
Trade Reporting Indicator
Y
Y
Y
2593
NoOrder Attributes
Y
Y
Y
Sent only on Ack route.
2594
Order Attribute Type
Y
Y
Y
2595
Order Attribute Value
Y
Y
Y
2704
Trading Instruction
Y
Y
Y
Sent only on Ack route.
5700
Locate Broker
Y
5701
LocateID
Y
8013
TradeRegPubReason
8014
TradePriceConditionsFlag
Y
Y
Y
8015
Order Attributes
Y
Y
Y
Sent only on Ack route.
20001
BrokerLEI
Y
Y
Y
20003
Buyside LEI
Y
Y
Y
Sent only on Ack route.
20063
SIExecFlag
Y
Y
Y
20072
APAFlag
Y
Y
Y
20073
TrnsReportMIC
Y
Y
Y
Connectivity Requests and Production Issues
FIX connectivity exposes an IP and Port over the existing Bloomberg routers at client data centers. The Bloomberg contacts for network connectivity requests and production issues are in the table below.

Request
Contact Information
New Requests and Sales
Bloomberg Sales:
Americas: +1 212 318 2000

EMEA: +44 20 7330 7500

Asia Pacific: +81 3 3201 8900

Implementation and Installations
Bloomberg Electronic Trading Installations (ETI):
Americas: +1 212 617 5820

EMEA: +44 20 7073 3833

Asia Pacific: + 81 3 3201 3582

Production Support
Bloomberg Global Electronic Trading Support:
Americas: +1 212 617 3430

EMEA: +44 20 7073 3330

Asia Pacific: +81 3 3201 8989

Appendix
Revision History
Version
Date
Notes
1.0.0-11
03 25 2024
Minor table adjustments.
1.0.0-9
02 20 2024
Updated Enterprise Console links to work for both bloomberg.com and blpprofessional.com.
1.0.0.1
11/02/2022
Created subsections and formatted Introduction.
1.0.0
07/02/2021
Created online version. Previously DOCS 2083983.
Terms of Use
This document is being provided for your use as a Bloomberg Trading Solutions customer and is subject to the terms and conditions of your applicable agreements with Bloomberg. This document may not be shared or distributed without Bloomberg’s express written consent.

The BLOOMBERG TERMINAL service and Bloomberg data products (the “Services”) are owned and distributed by Bloomberg Finance L.P. (“BFLP”) except that Bloomberg L.P. and its subsidiaries (“BLP”) distribute these products in Argentina, Australia and certain jurisdictions in the Pacific islands, Bermuda, China, India, Japan, Korea and New Zealand. BLP provides BFLP with global marketing and operational support. Certain features, functions, products and services are available only to sophisticated investors and only where permitted. BFLP, BLP and their affiliates do not guarantee the accuracy of prices or other information in the Services. Nothing in the Services shall constitute or be construed as an offering of financial instruments by BFLP, BLP or their affiliates, or as investment advice or recommendations by BFLP, BLP or their affiliates of an investment strategy or whether or not to “buy,” “sell” or “hold” an investment. Information available via the Services should not be considered as information sufficient upon which to base an investment decision. The following are trademarks and service marks of BFLP, a Delaware limited partnership, or its subsidiaries: BLOOMBERG, BLOOMBERG ANYWHERE, BLOOMBERG MARKETS, BLOOMBERG NEWS, BLOOMBERG PROFESSIONAL, BLOOMBERG TERMINAL and BLOOMBERG.COM. Absence of any trademark or service mark from this list does not waive Bloomberg’s intellectual property rights in that name, mark or logo. All rights reserved. © 2026 Bloomberg. This document and its contents may not be forwarded or redistributed without the prior written consent of Bloomberg.
