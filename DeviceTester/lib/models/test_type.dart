import 'package:flutter/material.dart';

class TestType {
  int? id;
  String? name;
  bool? status;
  String? message;
  Widget? content;

  TestType({this.id, this.name, this.status, this.message, this.content});

  TestType.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    status = json['status'];
    message = json['message'];
    content = json['content'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['status'] = this.status;
    data['message'] = this.message;
    data['content'] = this.content;
    return data;
  }
}
