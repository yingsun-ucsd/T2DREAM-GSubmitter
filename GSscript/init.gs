function init() {
  var userProperties=PropertiesService.getUserProperties();
  userProperties.deleteAllProperties();
  userProperties.setProperty("submit_server", "http://www.t2dream-demo.org");
  userProperties.setProperty("http://www.t2dream-demo.org", "XXXXXXXX:yyyyyyyyyyyyyyyy");
  
  var data = userProperties.getProperties();
  for (var key in data) {
    Logger.log('UserKey: %s, Value: %s', key, data[key]);
  }
}
