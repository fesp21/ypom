ypom
====

Your Place Or Mine - Decentral Secure Messaging

## Features
* Messaging App using MQTT and TweetNaCl
* Cross Platform IOS, Android, Python, ...
* Asymmetric encryption

## Messages

### user's public key
```
topic: ypom/<host>/<port>/<user-name>
message: {"_type":"usr","pk":"<public-key-in-base64>","name":"<user-name>",["dev":"<deviceToken>"]}
```

### message from user1 to user2
```
topic: ypom/<host-user1>/<port-user1>/<name-user1>/<host-user2>/<port-user2>/<name-user2>
message: {"_type":"msg","timestamp":"<timestamp>","content":"<content-in-base64>"}
```

### acknowledge message from user 1 received at user2
```
topic: ypom/<host-user1>/<port-user1>/<name-user1>/<host-user2>/<port-user2>/<name-user2>
message: {"_type":"ack","timestamp":"<timestamp>"}
```


## To be designed
* User Setup
* Groups

## Todo
* Web / Backend
* Android App
* Video/Photo/Audio
