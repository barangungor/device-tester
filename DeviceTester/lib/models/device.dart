class Device {
  String? brand;
  String? model;
  String? storage;

  Device({this.brand, this.model, this.storage});

  Device.fromJson(Map<String, dynamic> json) {
    brand = json['brand'];
    model = json['model'];
    storage = json['storage'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['brand'] = this.brand;
    data['model'] = this.model;
    data['storage'] = this.storage;
    return data;
  }

  @override
  String toString() {
    return 'Marka: $brand\nModel: $model\nHafıza: $storage';
  }
}
