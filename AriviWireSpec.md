<<<<<<< HEAD
# ARIVI Wire Specification 
=======
# ARIVI Wire Specification
>>>>>>> breaking out arivi-core from arivi

## Handshake Frame
This frame contains handshake of the connections, initially client sends list of the version available along with the ephemeral key and challenge cipher text with Handshake-Request field set, then server sends the negotiated protocol version, the decrepted challenge text decrypted using the shared secret key derived from ephemeral key

---
## Reset/Close Frame

This frame contains information about the closing/ resetting connection, If opcode field is RESET then session of the connection resets, if it is CLOSE the the connection closes

---

## Regular Frame

This type of contains the actual payload for the communication

---

### **Version**:
 Version of the Wire Spec this will be negotiated at the initial messages, Client and server will negotiated this by taking latest of common version, For Ex. Client has v1,v2 and Server has v1,v2,v3 then the communication version will be v2 , This field is 32 bit long.

---


### **Opcode**:

 -  **ERROR - 0x00**
	 - Indicates an error processing a request. The body of the message will be an error code followed by a error message. Then, depending on the exception, more content may follow. The error codes are defined in along with their additional content if any
<<<<<<< HEAD
    

- **Handshake-Request - 0x01** 
	- Shows that this is a Handshake-Request, Message payload contains all versions available at client, ephemeral public key of ecies and encrypted random challenge ciphertext

  

-   **Handshake-Response \- 0x02**
	- Shows that this is a Handshake-Response, Message payload contain version negotiated, the decrypted message received from Handshake-Request
    
-   **OPTIONS 0x03**
	- Asks the server to return what service options are supported. The body of an OPTIONS message should be empty and the server will respond with a SUPPORTED message such as services Kademlia,Chord,Block
   

-   **RESET 0x04**
	-  Resets the connection session
    

-   **CLOSE 0x05**
	-  Ends the current connection with the server
    

-   **PING 0x06**
	-   A Ping frame MAY include "Application data". Upon receipt of a Ping frame, an endpoint MUST send a Pong frame in  response, unless it already received a Close frame. It should respond with Pong frame as soon as is practical.
    
=======


- **Handshake-Request - 0x01**
	- Shows that this is a Handshake-Request, Message payload contains all versions available at client, ephemeral public key of ecies and encrypted random challenge ciphertext



-   **Handshake-Response \- 0x02**
	- Shows that this is a Handshake-Response, Message payload contain version negotiated, the decrypted message received from Handshake-Request

-   **OPTIONS 0x03**
	- Asks the server to return what service options are supported. The body of an OPTIONS message should be empty and the server will respond with a SUPPORTED message such as services Kademlia,Chord,Block


-   **RESET 0x04**
	-  Resets the connection session


-   **CLOSE 0x05**
	-  Ends the current connection with the server


-   **PING 0x06**
	-   A Ping frame MAY include "Application data". Upon receipt of a Ping frame, an endpoint MUST send a Pong frame in  response, unless it already received a Close frame. It should respond with Pong frame as soon as is practical.

>>>>>>> breaking out arivi-core from arivi

-   **PONG 0x07**
	-  A Pong frame sent in response to a Ping frame must have identical  
    "Application data" as found in the message body of the Ping frame  
    being replied to.

----

### **Public Flags:**

-   **Final Fragment :** A fragmented message consists of a single frame with the FIN bit clear and an opcode other than 0, followed by zero or more frames with the FIN bit clear and the opcode set to 0, and terminated by a single frame with the FIN bit set and an opcode of 0. A fragmented message is conceptually equivalent to a single larger message whose payload is equal to the concatenation of the payloads of the fragments in order.
<<<<<<< HEAD
    
-   **Text/Binary:** 
	- If set to 0, its assumed to be Binary, else it is ASCII text.
    
-   **Initiator:** 
	- This bit will be set to 1 if the Connection was initiated by this endpoint. Will be useful in maintain the counter/nonce exclusivity for certain symmetric encryption schemes like AES / Poly where unique nonce is needed.
    
=======

-   **Text/Binary:**
	- If set to 0, its assumed to be Binary, else it is ASCII text.

-   **Initiator:**
	- This bit will be set to 1 if the Connection was initiated by this endpoint. Will be useful in maintain the counter/nonce exclusivity for certain symmetric encryption schemes like AES / Poly where unique nonce is needed.

>>>>>>> breaking out arivi-core from arivi
-   **Encryption  Type (0 None,1 AES CTR, 2 PolyChaCha)**
	- This defines the encryption method used for encryption of payload , two bits is allocated for this

			00 - None

			01 - AES CTR Mode

			10 - ChaChaPoly

<<<<<<< HEAD
  
  

- **ConnectionId** 
	- This is 128 bit universally unique identifier (UUID) which is generated by client using [ Data.UUID.V4 ](https://hackage.haskell.org/package/uuid), so that each connection will get unique id

  
  

- **Payload-Length** 
=======



- **ConnectionId**
	- This is 128 bit universally unique identifier (UUID) which is generated by client using [ Data.UUID.V4 ](https://hackage.haskell.org/package/uuid), so that each connection will get unique id




- **Payload-Length**
>>>>>>> breaking out arivi-core from arivi
	- This denote the length of message in payload field. This field size is 3 Bytes which gives 2^(3*8) bits = 2 MB max size of payload actual size will be 500KB


 - **Payload**
		 - This is the actual payload of the frame which can be of max size 2MB but actual size is 500KB
