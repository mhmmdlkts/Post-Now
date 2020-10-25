import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:postnow/services/contact_form_service.dart';

class ContactFormScreen extends StatefulWidget {
  final User user;
  ContactFormScreen(this.user);

  @override
  _ContactFormState createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactFormScreen> {

  final TextEditingController _nameFieldController = TextEditingController();
  final TextEditingController _emailFieldController = TextEditingController();
  final TextEditingController _phoneFieldController = TextEditingController();
  final TextEditingController _subjectFieldController = TextEditingController();
  final TextEditingController _contentFieldController = TextEditingController();
  final double _space = 10;
  ContactFormService _contactFormService;
  bool _sendable = false;

  @override
  void initState() {
    super.initState();
    _contactFormService = ContactFormService(widget.user);
    _nameFieldController.text = widget.user.displayName;
    _contactFormService.init().then((value) => {
      setState(() {
        _emailFieldController.text = _contactFormService.email;
        _phoneFieldController.text = _contactFormService.phone;
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(("CONTACT_FORM.TITLE".tr()), style: TextStyle(color: Colors.white)),
          brightness: Brightness.dark,
          iconTheme:  IconThemeData(color: Colors.white),
        ),
        body: Form(
          child: ListView(
            padding: EdgeInsets.all(10),
            shrinkWrap: true,
            children: [
              TextFormField(
                textCapitalization: TextCapitalization.words,
                onChanged: _validator,
                controller: _nameFieldController,
                decoration:_getInputDecoration('CONTACT_FORM.NAME.LABEL', 'CONTACT_FORM.NAME.HINT_LABEL', Icons.person),
              ),
              Container(height: _space),
              TextFormField(
                onChanged: _validator,
                controller: _emailFieldController,
                decoration:_getInputDecoration('CONTACT_FORM.EMAIL.LABEL', 'CONTACT_FORM.EMAIL.HINT_LABEL', Icons.email),
              ),
              Container(height: _space),
              TextFormField(
                onChanged: _validator,
                controller: _phoneFieldController,
                decoration:_getInputDecoration('CONTACT_FORM.PHONE.LABEL', 'CONTACT_FORM.PHONE.HINT_LABEL', Icons.phone),
              ),
              Container(height: _space),
              TextFormField(
                textCapitalization: TextCapitalization.words,
                onChanged: _validator,
                controller: _subjectFieldController,
                decoration:_getInputDecoration('CONTACT_FORM.SUBJECT.LABEL', 'CONTACT_FORM.SUBJECT.HINT_LABEL', Icons.short_text),
              ),
              Container(height: _space),
              TextFormField(
                  textCapitalization: TextCapitalization.sentences,
                onChanged: _validator,
                controller: _contentFieldController,
                maxLines: null,
                minLines: 4,
                decoration:_getInputDecoration('CONTACT_FORM.CONTENT.LABEL', 'CONTACT_FORM.CONTENT.HINT_LABEL', Icons.subject)
              ),
              Container(height: _space),
              FlatButton(
                color: Colors.lightBlue,
                child: Text("CONTACT_FORM.SEND".tr(), style: TextStyle(color: Colors.white),),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                ),
                disabledColor: Colors.grey,
                onPressed: !_sendable? null : () {
                  setState(() {
                    _sendable = false;
                  });
                  _contactFormService.createRequest(
                    name: _nameFieldController.text,
                    email: _emailFieldController.text,
                    phone: _phoneFieldController.text,
                    subject: _subjectFieldController.text,
                    content: _contentFieldController.text,
                  ).then((value) => {
                    Navigator.of(context).pop()
                  });
                },
              ),
            ],
          ),
        )
    );
  }

  void _validator(val) {
    setState(() {
      _sendable =
          _nameFieldController.text.length != 0 &&
              _emailFieldController.text.length != 0 &&
              _phoneFieldController.text.length != 0 &&
              _subjectFieldController.text.length != 0 &&
              _contentFieldController.text.length != 0;
    });
  }

  InputDecoration _getInputDecoration(String labelKey, String hintText, IconData icon) {
    return InputDecoration(
      labelText: labelKey.tr(),
      hintText: hintText.tr(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.lightBlueAccent, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black45, width: 1.0),
      ),
    );
  }
}