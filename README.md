ypom
====

Your Place Or Mine - Decentral Secure Messaging

## Features
* Decentralised servers
* Messaging App using
** MQTT (https://github.com/ckrey/MQTT-Client-Framework.git) and
** NaCL (https://github.com/drewcrawford/libsodium-ios.git) and
** NWPusher (https://github.com/noodlewerk/NWPusher)
* Cross Platform IOS, Android, Python, ...
* Asymmetric encryption
* Secure key import/export
* Image send/receive/view
* User online status
* Store and forward messaging

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
Uses `crypto_box` and `crypto_box_open`.
Messages are sent to the broker without the retained-flag. QOS 2 is used to ensure the broker stores the messages while the receiver is not connected.

### acknowledgement message returned from user2 to user1
```
topic: ypom/<user1-pk-in-base32>/<user2-pk-in-base32>
message: <nonce-in-base64>:<json-encrypted-in-base64>
json:{"_type":"ack","timestamp":"<timestamp>"}
```
Uses `crypto_box` and `crypto_box_open`.
This is sent immediately after reception of the original message.

## Key import/export format
```
keys:<nonce-in-base64>:<json-encrypted-in-base64>
json:{"username":"<name>","pk":"<pk-in-base64>","sk":"<sk-in-base64>"}
```

Use `crypto_stream_xor` with a user-provide passphrase to encrypt/decrypt json.
Client provides mechanism to copy/past keys to/from email, addressbook, files...

## To be designed
* User Setup
* Groups

## Todo
* Web / Backend
* Android App
* Video/Audio

## Killer Features
* Group Poll 
* Show online state of friends / group members
* search and send images directly from the web? (telegram)
* background image
* themes / cost money
* thank you for the colors, Stefanie
