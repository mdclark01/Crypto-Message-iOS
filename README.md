# Crypto-Message-iOS

A iOS messaging application. 

All text messages are encrypted using AES & Public / Private Key Pairs.

Each user generates a public and private key pair on device registration. 
The public key is then uploaded to the server and will be used to encrypt AES keys of messages sent the recipient.
Additionally each message is encrypted with a new AES key.

Server side code not included in this repo.
