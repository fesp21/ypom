ypom
====

Your Place Or Mine - Decentral Secure Messaging

## Features
* Messaging App using MQTT and TweetNaCl (libsodium to come)
* Cross Platform IOS, Android, Python, ...
* Asymmetric encryption

## Messages

### user's public key
```
topic: ypom//<public-key-in-base32>
message: {"_type":"usr","pk":"<public-key-in-base64>","name":"<user-name>",["dev":"<deviceToken-in-base64>"]}

message: unencrypted JSON
```

This key message is written when the client starts or changes it's broker or identity. The message is sent to the broker with the retained-flag set.

### message from user1 to user2
```
topic: ypom/<user2-pk-in-base32>/<user1-pk-in-base32>
message: <nonce-in-base64>:<json-encrypted-in-base64>
json: {"_type":"msg","timestamp":"<timestamp>","content":"<content-in-base64>",["content-type":"<mime-type>"]}

timestamp: seconds since 1.1.1970 w/ milliseconds as decimals e.g. "12345678.123"
```
Messages are sent to the broker without the retained-flag. QOS 2 is used to ensure the broker stores the messages while the receiver is not connected.

### acknowledgement message returned from user2 to user1
```
topic: ypom/<user1-pk-in-base32>/<user2-pk-in-base32>
message: <nonce-in-base64>:<json-encrypted-in-base64>
json:{"_type":"ack","timestamp":"<timestamp>"}
```

This is sent immediately after reception of the original message.

## To be designed
* User Setup
* Groups

## Todo
* Web / Backend
* Android App
* Video/Photo/Audio
* Move IOS to libsodium
