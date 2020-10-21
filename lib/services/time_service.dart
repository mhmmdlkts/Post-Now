DateTime stringToDateTime(String dateTime_string) {
  if (dateTime_string == null)
    return null;
  return DateTime.parse(dateTime_string).toLocal();
}

String dateTimeToString(DateTime dateTime) {
  if (dateTime == null)
    return null;
  return dateTime.toString();
}