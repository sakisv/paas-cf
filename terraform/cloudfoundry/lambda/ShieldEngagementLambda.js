// ShieldEngagementLambda.js
// Source https://s3.amazonaws.com/aws-shield-lambda/ShieldEngagementLambda.js
// User configurable options
var config = {
  // Change this to "critical" if you are subscribed to Enterprise Support
  severity: 'urgent',

  // Change this to 'advanced' if you are subscribed to AWS Shield Advanced
  shield: 'standard',

  // Change this to 'off' after testing
  test: 'on',

  // Modify subject and message if not subscribed to AWS Shield Advanced
  // Change subject and message to the path of a .txt file that you created in S3
  standardSubject: 'http://s3.amazonaws.com/aws-shield-lambda/EngagementSubject.txt',
  standardMessage: 'http://s3.amazonaws.com/aws-shield-lambda/EngagementBody.txt'
}


// ---- do not edit below this line ----
var ShieldClass = function(config, context, lambdaCallback) {
  var self = this;
  var AWS  = require('aws-sdk');
  var http = require('http');

  initialize = function() {
      self.advancedSubject = 'http://s3.amazonaws.com/aws-shield-lambda/ShieldAdvancedSubject.txt';
      self.advancedMessage = 'http://s3.amazonaws.com/aws-shield-lambda/ShieldAdvancedMessage.txt';
      self.subjectUrl = config.shield == 'advanced' ? self.advancedSubject : config.standardSubject;
      self.messageUrl = config.shield == 'advanced' ? self.advancedMessage : config.standardMessage;
      self.message = '';
      self.subject = '';
      self.snsParams = {
          Message : '',
          TopicArn: ''
      }
      self.passMessage = "Unable to complete function execution";
      self.passCount   = 0;
      setSNSTopicArn(config.test);
      s3PullTxt(self.subjectUrl, 'subject');
      s3PullTxt(self.messageUrl, 'message');
      s3PullPromise(0, createCase, sendPage);
      passCheck(0, lambdaCallback);
  }

  setSNSTopicArn = function(testStatus) {
      if (testStatus == 'off') {
          self.snsParams.TopicArn = 'arn:aws:sns:us-east-1:832974201822:DDoSIoTEscalations';
      } else {
          self.snsParams.TopicArn = 'arn:aws:sns:us-east-1:832974201822:DDoSIoTTest';
      }
  }

  s3PullPromise = function(timeout, callback, callbackOfCallback) {
      if (timeout > 10000) {
          console.log('Unable to complete S3 subject/message pull');
          return false;
      }
      if (self.subject == '' || self.message == '') {
          timeout += 20;
          setTimeout(function() { s3PullPromise(timeout, callback, callbackOfCallback) }, 20);
      } else {
          self.passCount++;
          callback (callbackOfCallback);
      }
  }

  s3PullTxt = function(s3Url, target) {
      http.get(s3Url, function(response) {
      response
          .on('data', function(chunk) {
              self[target] += chunk;
          })
          .on('end' , function() {
              if (self[target]== '') {
              self[target] = 'Unable to retrieve text';
              }
          })
      });
  }

  createCase = function(callback) {
      var params = {
          communicationBody: self.message,
          categoryCode     : 'inbound-to-aws',
          serviceCode      : 'distributed-denial-of-service',
          severityCode     : config.severity,
          subject          : self.subject
      }
      var support = new AWS.Support({
          region: 'us-east-1'
      });
      support.createCase(params, function(err, data) {
          if (err) {
              console.log(err, err.stack);
          } else {
              var params = {
                  caseIdList: [
                      data.caseId,
                  ],
              }
              support.describeCases(params, callback);
          }
      });
  }

  passCheck = function(timeout, callback) {
      if (self.passCount > 2) {
          callback(null, self.passMessage);
          return;
      }
      if (timeout > 10000) {
          var err = new Error(self.passMessage);
          callback(err);
      } else {
          timeout += 20;
          setTimeout(function() { passCheck(timeout, callback) }, 20);
      }
  }

  sendPage = function(err, data) {
      self.passCount++;
      if (err) {
          console.log(err, err.stack);
      } else {
          self.snsParams.Message =
              "\nCase ID " + data.cases[0].displayId +
              "\nCustomer ID " + data.cases[0].caseId.split('-')[1];
          snsPublish();
      }
  }

  snsPublish = function() {
      var sns = new AWS.SNS({region: self.snsParams.TopicArn.split(':')[3]});
      sns.publish(self.snsParams, function(err, data) {
          console.log(context);
          if (data == null) {
              self.passMessage = "Failed to publish to SNS" + self.snsParams + err;
          } else {
              self.passMessage = "DDoS Escalation Successful";
              self.passCount++;
        }
      });
  }

initialize();
}

exports.handler = (event, context, callback) => {
  var shield = new ShieldClass(config, context, callback);
};
