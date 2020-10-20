class Price {
  double total;
  double voucher;
  double payed;
  double toBePaid;
  double driverBecomes;

  Price.fromJson(Map json) {
    if (json["total"] != null)
      total = json["total"] + 0.0;
    if (json["voucher"] != null)
      voucher = json["voucher"] + 0.0;
    if (json["payed"] != null)
      payed = json["payed"] + 0.0;
    if (json["toBePaid"] != null)
      toBePaid = json["toBePaid"] + 0.0;
    if (json["driverBecomes"] != null)
      driverBecomes = json["driverBecomes"] + 0.0;
  }

  Map toMap() => {
    "total": total,
    "voucher": voucher,
    "payed": payed,
    "toBePaid": toBePaid,
    "driverBecomes": driverBecomes
  };
}