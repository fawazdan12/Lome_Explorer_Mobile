import 'package:flutter/material.dart';
import 'package:event_flow/data/models/business_card_model.dart';

class BusinessCardProvider extends ChangeNotifier{
  final _card = BusinessCardModel(
    name: 'DANGO NADEY Abdoul Fawaz',
    title: 'Developpeur Full Stack web et mobile',
    company: 'Freelance',
    email: 'fawazdango28@gmail.com',
    phone: '+228 71 86 18 89',
    website: 'https://github.com/fawazdan12'
  );

  BusinessCardModel get card => _card;

  
  void updateName(String newName){
    _card.name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail){
    _card.email = newEmail;
    notifyListeners();
  }

  void updateTitle(String newTitle){
    _card.title = newTitle;
    notifyListeners();
  }

  void updateCompany(String newCompany){
    _card.company = newCompany;
    notifyListeners();
  }

  void updateWebsite(String newWebsite){
    _card.website = newWebsite;
    notifyListeners();
  }

  void updatePhone(String newPhone){
    _card.phone = newPhone;
    notifyListeners();
  }
} 