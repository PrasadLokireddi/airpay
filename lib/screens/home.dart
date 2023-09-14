import 'package:airpay_flutter_package/airpay_package.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:crc32_checksum/crc32_checksum.dart';

class Home extends StatefulWidget {
  final bool isSandbox;
  Home({required this.isSandbox});

  @override
  _HomeState createState() => _HomeState(isSandbox: isSandbox);
}


class _HomeState extends State<Home> {
  final bool isSandbox;


  final RegExp _emojiRegex = RegExp(
    r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{1FAB0}-\u{1FAB6}\u{1FAC0}-\u{1FAC2}\u{1FAD0}-\u{1FAD9}\u{1FADA}-\u{1FADB}\u{1FADC}-\u{1FADD}\u{1FAE0}-\u{1FAE1}\u{1FAE2}-\u{1FAE3}\u{1FAE4}-\u{1FAE5}\u{1FAE6}-\u{1FAE7}\u{1FAE8}-\u{1FAE9}\u{1FAEA}-\u{1FAEB}]',
    unicode: true,
  );
  final RegExp regex = RegExp(r'[^a-zA-Z]');
  final RegExp email_regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');


  _HomeState({required this.isSandbox});

  bool isSuccess = false;
  bool isVisible = false;
  bool isSubVisible = false;
  TextEditingController fname = TextEditingController();
  TextEditingController lname = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController phone = TextEditingController();
  TextEditingController city = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController pincode = TextEditingController();
  TextEditingController orderId = TextEditingController();
  TextEditingController amount = TextEditingController();
  TextEditingController fullAddress = TextEditingController();
  TextEditingController subscription_date = TextEditingController();
  TextEditingController subscription_frequency = TextEditingController();
  TextEditingController subscription_max_amount = TextEditingController();
  TextEditingController subscription_amount = TextEditingController();
  TextEditingController subscription_rec_count = TextEditingController();
  TextEditingController txn_subtype = TextEditingController();
  DateTime selectedDate = DateTime.now().add(Duration(days: 2)); // Start from 2 days in the future
  List<String> subscription_period = ['Day', 'Week', 'Month', 'Year', 'Adhoc'];
  List<String> subscription_retry = ['No', 'Yes'];

  String dropdownValue ="";
  String subRetryValue ="";



  void _showAddress() {
    setState(() {
      isVisible = !isVisible;

    });
  }
  void _showSubscription() {
    setState(() {
      isSubVisible = !isSubVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    dropdownValue = "D";
    subRetryValue = "0";
    fname.text = "";
    lname.text = "";
    email.text = "";
    phone.text = "";
    fullAddress.text = "";
    pincode.text = "";
    orderId.text = "";
    amount.text = "";
    city.text = "";
    state.text = "";
    country.text = "";
  }

  int calculateCRC32(String input) {
    final List<int> crcTable = List<int>.generate(256, (int index) {
      var crc = index;
      for (var j = 0; j < 8; j++) {
        if (crc & 1 == 1) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
      return crc & 0xFFFFFFFF;
    });

    int crc = 0xFFFFFFFF;
    final List<int> bytes = input.codeUnits;

    for (final byte in bytes) {
      crc = (crc >> 8) ^ crcTable[(crc ^ byte) & 0xFF];
    }

    return crc ^ 0xFFFFFFFF;
  }

  onComplete(status, response) {
    var resp = response.toJson();
    print(resp);
    var txtStsMsg = resp['STATUSMSG'] ?? "";
    var txtSts = resp['TRANSACTIONSTATUS'] ?? "";
    Navigator.pop(context);
    if (txtStsMsg == '') {
      txtStsMsg = response['STATUSMSG'] ?? "";
      txtSts = response['TRANSACTIONSTATUS'] ?? "";
    }
    if (txtStsMsg == 'Invalid Checksum') {
      // txtStsMsg = "Transaction Canceled";
    }

    var transid = resp['MERCHANTTRANSACTIONID'] ?? "";
    var apTransactionID = resp['TRANSACTIONID'] ?? "";
    var amount = resp['TRANSACTIONAMT'] ?? "";
    var transtatus = resp['TRANSACTIONSTATUS'] ?? "";
    var message = resp['STATUSMSG'] ?? "";
    var customer_vpa ="";
    var customer_fvpa ="";
    var chmode = resp['CHMOD'] ?? "";
    var secureHash = resp['AP_SECUREHASH'] ?? "";


    //(!TextUtils.isEmpty(transaction.getChMode()) && transaction.getChMode().equalsIgnoreCase("upi")){
    if(!chmode.toString().isEmpty && chmode.toString() == "upi" ){
      customer_vpa = resp['CUSTOMERVPA'] ?? "";
      customer_fvpa = ":$customer_vpa";
    }
    var merchantid = ""; //Please enter Merchant Id
    var username = "";   //Please enter Username


// Calculate the CRC32 checksum

    var sParam =
        '${transid}:${apTransactionID}:${amount}:${transtatus}:${message}:${merchantid}:${username}$customer_fvpa';



    var checkSumResult = Crc32.calculate(sParam);


    if(checkSumResult.toString() == secureHash.toString()){
      Fluttertoast.showToast(
          msg: "Securehash matched",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white24,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }else{
      Fluttertoast.showToast(
          msg: "Securehash mis-matched",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white24,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }


    AwesomeDialog(
        context: context,
        dialogType: DialogType.NO_HEADER,
        headerAnimationLoop: true,
        animType: AnimType.BOTTOMSLIDE,
        //title: "AirPay",
        desc: 'Transaction Status: ' +
            txtSts +
            '\nTransaction Status Message: ' +
            txtStsMsg)
        .show();
  }

  void ValidateFields() {
    var msg = '';
    if (fname.text.length < 2) {
      msg = 'Enter first name';
    } else if (RegExp(r"^[a-zA-Z0-9]+$").hasMatch(fname.text) == false) {
      msg = 'Enter a valid first name';
    } else if (lname.text.isEmpty) {
      msg = 'Enter last name';
    } else if (RegExp(r"^[a-zA-Z0-9]+$").hasMatch(lname.text) == false) {
      msg = 'Enter a valid last name';
    } else if (email.text.isEmpty && phone.text.isEmpty) {
      msg = 'Enter an email ID or phone number';
    } else if (email.text.isNotEmpty &&
        RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9._`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
            .hasMatch(email.text) ==
            false) {
      msg = "Please enter a valid email";
    } else if (phone.text.isNotEmpty && phone.text.length < 10) {
      msg = 'Enter a valid phone number';
    } else if (orderId.text.isEmpty) {
      msg = 'Enter order ID';
    } else if (amount.text.isEmpty) {
      msg = 'Enter an amount to proceed';
    } else if (amount.text == '0') {
      msg = 'Enter valid amount to proceed';
    }
    else if(txn_subtype.text == "12" && subscription_date.text.toString().isEmpty){
      msg = 'Enter valid Subscription Next Run Date';
    }
    else if(txn_subtype.text == "12" && subscription_frequency.text.toString().isEmpty){
      msg = 'Enter valid Subscription Frequency';
    }
    else if(txn_subtype.text == "12" && subscription_max_amount.text.toString().isEmpty){
      msg = 'Enter valid Subscription Max Amount';
    }
    else if(txn_subtype.text == "12" && subscription_amount.text.toString().isEmpty){
      msg = 'Enter valid Subscription Amount';
    }
    else if(txn_subtype.text == "12" && subscription_rec_count.text.toString().isEmpty){
      msg = 'Enter valid Subscription Recurring Count';
    }

    if (msg.isNotEmpty) {
      AwesomeDialog(
          context: context,
          dialogType: DialogType.NO_HEADER,
          headerAnimationLoop: true,
          animType: AnimType.BOTTOMSLIDE,
          btnOkOnPress: () {},
          btnOkColor: Colors.red,
          desc: msg)
          .show();
      return;
    }





//Testing Credentails
    String domainPath = ''; // Please enter same input as successurl

    String kAirPaySecretKey = ''; // Please enter secret Key

    String kAirPayUserName = ''; //Please enter username

    String kAirPayPassword = ''; //Please enter password

    String merchantID = ''; //Please enter merchant id

    String successURL = ''; // Please enter successurl

    String failedURL = ''; // Please enter same input as successurl

    //Private Key and Checksum
    var date = new DateTime.now();
    var format = DateFormat("yyyy-MM-dd");
    var formattedDate = format.format(date);
    var temp = utf8.encode(
        '${kAirPaySecretKey.toString()}@${kAirPayUserName.toString()}:|:${kAirPayPassword.toString()}');
    var privatekey = sha256.convert(temp);



    var siindexvar = '${subscription_date.text}${subscription_frequency.text}${dropdownValue.toString()}${subscription_amount.text}${"1"}${subscription_rec_count.text}${subRetryValue.toString()}';
    if(txn_subtype.text.toString() == "12"){
      siindexvar = siindexvar;
    }else{
      siindexvar = "";
    }

    var setAllStr =
        '${email.text}${fname.text}${lname.text}${fullAddress.text}${city.text}${state.text}${country.text}${amount.text
        .toString()}${orderId.text
        .toString()}${siindexvar.toString()}$formattedDate';


    // key for checksum
    var sTemp2 =
    utf8.encode('${kAirPayUserName
        .toString()}~:~${kAirPayPassword
        .toString()}');
    var sKey = sha256.convert(sTemp2);
    // checksum
    var sAllData = utf8.encode('$sKey@$setAllStr');


    var checksum = sha256.convert(sAllData);

    UserRequest user = UserRequest(
        privatekey: privatekey.toString(),
        checksum: checksum.toString(),
        mercid: merchantID,
        protoDomain: domainPath,
        buyerFirstName: fname.text,
        buyerLastName: lname.text,
        buyerEmail: email.text,
        buyerPhone: phone.text,
        buyerAddress: fullAddress.text,
        buyerPinCode: pincode.text,
        orderid: orderId.text,
        amount: amount.text,
        buyerCity: city.text,
        buyerState: state.text,
        buyerCountry: country.text,
        currency: "356",
        isocurrency: "INR",
        chmod: "",
        customvar: "test",
        txnsubtype: txn_subtype.text,
        wallet: "0",
        isStaging: this.isSandbox, //True for the Staging
        successUrl: successURL,
        failedUrl: failedURL,
        sb_nextrundate: subscription_date.text,
        sb_period: dropdownValue.toString(),
        sb_frequency: subscription_frequency.text,
        sb_amount: subscription_amount.text,
        sb_isrecurring: "1",
        sb_recurringcount: subscription_rec_count.text,
        sb_retryattempts: subRetryValue,
        sb_maxamount: subscription_max_amount.text
    );




    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => new AirPay(
            user: user,
            closure: (status, response) => {onComplete(status, response)}),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().add(Duration(days: 2)), // Set the minimum selectable date
      lastDate: DateTime(2101), // Set a far future date as the maximum selectable date
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        final formattedDate = DateFormat('dd/MM/yyyy').format(selectedDate.toLocal());
        //subscription_date.text = selectedDate.toLocal().toString().split(' ')[0];
        subscription_date.text = formattedDate;

      });
    }
  }




  @override
  Widget build(BuildContext context) {
    String newValue = "";
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Image.asset(
            'assets/airpays.png',
            height: 40,
            color: Colors.white,
            width: 200,
          ),
          backgroundColor: Colors.blue[900],
        ),
        backgroundColor: Colors.grey[400],
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  margin: EdgeInsets.fromLTRB(8.0, 8, 8.0, 4),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12.0, 2.0, 12.0, 15.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Personal Information',
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                  'First Name *',
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.blue[900]),
                                )),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                              child: Text(
                                'Last Name *',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                  child: TextFormField(
                                  inputFormatters: [
                                    // FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+$')),
                                    FilteringTextInputFormatter.deny(_emojiRegex),
                                    FilteringTextInputFormatter.deny(regex),

                                    new LengthLimitingTextInputFormatter(18),
                                  ],
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    hintText: 'First Name',
                                    //   contentPadding: EdgeInsets.all(2.0),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 15.0),
                                  ),
                                  controller: fname,
                                )),
                            SizedBox(
                              width: 10.0,
                            ),
                            Expanded(
                              child: TextFormField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(_emojiRegex),
                                  FilteringTextInputFormatter.deny(regex),
                                  // FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+$')),
                                  new LengthLimitingTextInputFormatter(18),
                                ],
                                keyboardType: TextInputType.name,
                                decoration: InputDecoration(
                                  hintText: 'Last Name',
                                  // contentPadding: EdgeInsets.all(2.0),
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 15.0),
                                ),
                                controller: lname,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Container(
                          child: TextFormField(
                            validator: (value) => EmailValidator.validate(value!)
                                ? null
                                : "Please enter a valid email",
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(_emojiRegex),

                              // FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9]+$')),
                            ],
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'Email Id',
                              // contentPadding: EdgeInsets.all(2.0),
                              hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 15.0),
                            ),
                            controller: email,
                          ),
                        ),
                        SizedBox(
                          height: 8.0,
                        ),
                        Container(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.deny(_emojiRegex),
                              new LengthLimitingTextInputFormatter(
                                  10), // for mobile
                              FilteringTextInputFormatter.digitsOnly
                            ], // Only numbers can be entered
                            decoration: InputDecoration(
                              hintText: 'Phone',
                              // contentPadding: EdgeInsets.all(2.0),
                              hintStyle:
                              TextStyle(color: Colors.grey, fontSize: 15.0),
                            ),
                            controller: phone,
                          ),
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                      ],
                    ),
                  ),
                ),
                Visibility(
                    visible: true,
                    child: Card(
                      margin: EdgeInsets.fromLTRB(8.0, 8, 8.0, 4),
                      color: Colors.white,
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(8.0, 8, 8.0, 4),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Address',
                                    style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showAddress();
                                    },
                                    icon: isVisible
                                        ? Icon(Icons.arrow_drop_up)
                                        : Icon(Icons.arrow_drop_down),
                                    color: Colors.black,
                                  )
                                ],
                              ),
                              Visibility(
                                visible: isVisible,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      child: TextFormField(
                                        inputFormatters: <TextInputFormatter>[
                                          //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                          FilteringTextInputFormatter.deny(_emojiRegex),
                                          new LengthLimitingTextInputFormatter(
                                              254),
                                        ],
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: 'Full Address',
                                          // contentPadding: EdgeInsets.all(2.0),
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15.0),
                                        ),
                                        controller: fullAddress,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    Container(
                                      child: TextFormField(
                                        inputFormatters: <TextInputFormatter>[
                                          //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                          FilteringTextInputFormatter.deny(_emojiRegex),
                                          new LengthLimitingTextInputFormatter(
                                              18),
                                        ],
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: 'City Name',
                                          // contentPadding: EdgeInsets.all(2.0),
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15.0),
                                        ),
                                        controller: city,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                              'State Name',
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  color: Colors.blue[900]),
                                            )),
                                        SizedBox(
                                          width: 8.0,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Country Name',
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                color: Colors.blue[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: TextFormField(
                                              inputFormatters: <TextInputFormatter>[
                                                //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                                FilteringTextInputFormatter.deny(_emojiRegex),
                                                new LengthLimitingTextInputFormatter(
                                                    18),
                                              ],
                                              keyboardType: TextInputType.name,
                                              decoration: InputDecoration(
                                                hintText: 'State',
                                                //   contentPadding: EdgeInsets.all(2.0),
                                                hintStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 15.0),
                                              ),
                                              controller: state,
                                            )),
                                        SizedBox(
                                          width: 10.0,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            inputFormatters: <
                                                TextInputFormatter>[
                                              //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                              FilteringTextInputFormatter.deny(_emojiRegex),
                                              new LengthLimitingTextInputFormatter(
                                                  18),
                                            ],
                                            keyboardType: TextInputType.name,
                                            decoration: InputDecoration(
                                              hintText: 'Country ',
                                              // contentPadding: EdgeInsets.all(2.0),
                                              hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15.0),
                                            ),
                                            controller: country,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 8.0,
                                    ),
                                    Container(
                                      child: TextFormField(
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.deny(_emojiRegex),
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          new LengthLimitingTextInputFormatter(
                                              8),
                                        ],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'PinCode',
                                          // contentPadding: EdgeInsets.all(2.0),
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15.0),
                                        ),
                                        controller: pincode,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15.0,
                                    ),
                                  ],
                                ),
                              ),
                              //Subscription Child
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Subscription',
                                    style: TextStyle(
                                        color: Colors.blue[900],
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _showSubscription();
                                    },
                                    icon: isSubVisible
                                        ? Icon(Icons.arrow_drop_up)
                                        : Icon(Icons.arrow_drop_down),
                                    color: Colors.black,
                                  )
                                ],
                              ),

                              Visibility(
                                visible: isSubVisible,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                  CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      child: TextFormField(
                                        inputFormatters: <TextInputFormatter>[
                                          FilteringTextInputFormatter.deny(_emojiRegex),
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          new LengthLimitingTextInputFormatter(
                                              2),
                                        ],
                                        keyboardType: TextInputType.number,
                                        decoration: InputDecoration(
                                          hintText: 'Txn Subtype',
                                          // contentPadding: EdgeInsets.all(2.0),
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15.0),
                                        ),
                                        controller: txn_subtype,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 15.0,
                                    ),
                                    Text(
                                      'Subscription Next Run Date',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          color: Colors.blue[900]),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    Container(
                                      child: TextFormField(
                                        inputFormatters: <TextInputFormatter>[
                                          //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                          FilteringTextInputFormatter.deny(_emojiRegex),
                                          new LengthLimitingTextInputFormatter(
                                              254),
                                        ],
                                        keyboardType: TextInputType.text,
                                        decoration: InputDecoration(
                                          hintText: 'Subscription Next Run Date',
                                          // contentPadding: EdgeInsets.all(2.0),
                                          hintStyle: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 15.0),
                                        ),
                                        controller: subscription_date,
                                        onTap: () => _selectDate(context),
                                      ),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    Text(
                                      'Period',
                                        style: TextStyle(
                                            fontSize: 18.0,
                                            color: Colors.blue[900]),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    DropdownMenu<String>(
                                      initialSelection: subscription_period.first,
                                      onSelected: (String ? value){
                                        setState(() {
                                          dropdownValue = value!;
                                          if(dropdownValue =="Day"){
                                            dropdownValue = "D";
                                          }else if(dropdownValue =="Week"){
                                            dropdownValue = "W";
                                          }else if(dropdownValue =="Month"){
                                            dropdownValue = "M";
                                          }else if(dropdownValue =="Year"){
                                            dropdownValue = "Y";
                                          }else if(dropdownValue =="Adhoc"){
                                            dropdownValue = "A";
                                          }

                                        });
                                      },
                                      dropdownMenuEntries: subscription_period.map<DropdownMenuEntry<String>>((String value) {
                                        return DropdownMenuEntry<String>(value: value, label: value);
                                      }).toList(),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                              'Frequency',
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  color: Colors.blue[900]),
                                            )),
                                        SizedBox(
                                          height: 10.0,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Max Amount',
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                color: Colors.blue[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: TextFormField(
                                              inputFormatters: <TextInputFormatter>[
                                                //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                                FilteringTextInputFormatter.deny(_emojiRegex),
                                                new LengthLimitingTextInputFormatter(
                                                    18),
                                              ],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: 'Frequency',
                                                //   contentPadding: EdgeInsets.all(2.0),
                                                hintStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 15.0),
                                              ),
                                              controller: subscription_frequency,
                                            )),
                                        SizedBox(
                                          width: 10.0,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            inputFormatters: <
                                                TextInputFormatter>[
                                                FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                                FilteringTextInputFormatter.deny(_emojiRegex),
                                              new LengthLimitingTextInputFormatter(
                                                  18),
                                            ],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: 'Max Amount ',
                                              // contentPadding: EdgeInsets.all(2.0),
                                              hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15.0),
                                            ),
                                            controller: subscription_max_amount,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: Text(
                                              'Subcription Amount',
                                              style: TextStyle(
                                                  fontSize: 18.0,
                                                  color: Colors.blue[900]),
                                            )),
                                        SizedBox(
                                          height: 10.0,
                                        ),
                                        Expanded(
                                          child: Text(
                                            'Recurring Count',
                                            style: TextStyle(
                                                fontSize: 18.0,
                                                color: Colors.blue[900]),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                            child: TextFormField(
                                              inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                                  FilteringTextInputFormatter.deny(_emojiRegex),
                                                new LengthLimitingTextInputFormatter(
                                                    18),
                                              ],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                hintText: 'Subscription Amount',
                                                //   contentPadding: EdgeInsets.all(2.0),
                                                hintStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 15.0),
                                              ),
                                              controller: subscription_amount,
                                            )),
                                        SizedBox(
                                          height: 10.0,
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            inputFormatters: <
                                                TextInputFormatter>[
                                              new LengthLimitingTextInputFormatter(3),
                                              //  FilteringTextInputFormatter.allow(RegExp(r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                              FilteringTextInputFormatter.deny(_emojiRegex),
                                              FilteringTextInputFormatter.digitsOnly,
                                              new LengthLimitingTextInputFormatter(
                                                  18),
                                            ],
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: 'Recurring Count',
                                              // contentPadding: EdgeInsets.all(2.0),
                                              hintStyle: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 15.0),
                                            ),
                                            controller: subscription_rec_count,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    Text(
                                      'Retry Attempts:',
                                      style: TextStyle(
                                          fontSize: 18.0,
                                          color: Colors.blue[900]),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),
                                    DropdownMenu<String>(
                                      initialSelection: subscription_retry.first,
                                      onSelected: (String ? value){
                                        setState(() {
                                          subRetryValue = value!;

                                          if(subRetryValue == "No"){
                                            subRetryValue = "0";
                                          }else {
                                            subRetryValue = "1";
                                          }

                                        });
                                      },
                                      dropdownMenuEntries: subscription_retry.map<DropdownMenuEntry<String>>((String value) {
                                        return DropdownMenuEntry<String>(value: value, label: value);
                                      }).toList(),
                                    ),
                                    SizedBox(
                                      height: 10.0,
                                    ),

                                  ],
                                ),
                              ),

                            ],

                          )),
                    )),
                Card(
                  margin: EdgeInsets.all(8.0),
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Transaction Information',
                          style: TextStyle(
                              fontSize: 20.0,
                              color: Colors.blue[900],
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: Text(
                                  'Order Id *',
                                  style: TextStyle(
                                      fontSize: 18.0, color: Colors.blue[900]),
                                )),
                            SizedBox(
                              width: 8.0,
                            ),
                            Expanded(
                              child: Text(
                                'Amount *',
                                style: TextStyle(
                                    fontSize: 18.0, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                                child: TextFormField(
                                  inputFormatters: [
                                    new LengthLimitingTextInputFormatter(20),
                                    FilteringTextInputFormatter.deny(_emojiRegex),
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'([a-zA-Z0-9])')),
                                  ],
                                  keyboardType: TextInputType.name,
                                  decoration: InputDecoration(
                                    hintText: 'Order Id',
                                    //   contentPadding: EdgeInsets.all(2.0),
                                    hintStyle: TextStyle(
                                        color: Colors.grey, fontSize: 15.0),
                                  ),
                                  controller: orderId,
                                )),
                            SizedBox(
                              width: 8.0,
                            ),
                            Expanded(
                              child: TextFormField(
                                inputFormatters: [
                                  FilteringTextInputFormatter.deny(_emojiRegex),
                                  FilteringTextInputFormatter.allow(RegExp(
                                      r'(^[0-9]{0,7}(?:\.[0-9]{0,2})?)')),
                                ],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: 'Amount',
                                  // contentPadding: EdgeInsets.all(2.0),
                                  hintStyle: TextStyle(
                                      color: Colors.grey, fontSize: 15.0),
                                ),
                                controller: amount,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 15.0,
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    // padding: EdgeInsets.fromLTRB(2.0, 11.0, 2.0, 11.0),
                    onPressed: () {
                      ValidateFields();
                    },
                    // color: Colors.blue[900],
                    child: Text(
                      'NEXT',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    // padding: EdgeInsets.fromLTRB(2.0, 11.0, 2.0, 11.0),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    // color: Colors.blue[900],
                    child: Text(
                      'BACK',
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
