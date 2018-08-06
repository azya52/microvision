#define VDD A0  //PC0
#define PROG A1 //PC1
#define TEST0 A3  //PC3
#define RESET A2  //PC2
#define EA A4 //PC4
#define LED PD5

#define BURN_TIME 50 // 50-60 ms

#define ADDRESS_SIZE 11

uint8_t portAddress[ADDRESS_SIZE] = {PD2, PD3, PD4, 13, 12, 11, 10, 9, 8, PD7, PD6}; //atmega8
//uint8_t portAddress[ADDRESS_SIZE] = {PD2, PD3, PD4, PD5, PD6, PD7, 8, 9, 10, 11, 12}; //nano

uint8_t receiveCommandPos = 0;
char receiveCommand[6];

#define ACK 0x06
#define NAK 0x15
uint8_t programMode = 0;
uint16_t firmwareSize = 0;
uint16_t burnAddress = 0;

void setFirstStage(){
  digitalWrite(VDD, LOW); // Set VDD to +5V
  digitalWrite(PROG, LOW); // Set PROG to +5V
  digitalWrite(TEST0, HIGH); // Set TEST0 to +5V
  digitalWrite(RESET, LOW); // Set RESET to 0V
  digitalWrite(EA, LOW); // Set EA to +5V
}

void setup() {
  // Setup the Control-Pins
  Serial.begin(9600);
  pinMode(LED, OUTPUT);
  digitalWrite(LED, LOW);
  pinMode(VDD, OUTPUT);
  pinMode(PROG, OUTPUT);
  pinMode(TEST0, OUTPUT);
  pinMode(RESET, OUTPUT);
  pinMode(EA, OUTPUT);
  setFirstStage();
  // Set the control-Pins according to MCS-48 recommendation
  digitalWrite(LED, HIGH);
  digitalWrite(LED, LOW);
}

void loop() {
  checkReceive();
}

void startFirmware() {
  digitalWrite(TEST0, LOW);
  digitalWrite(EA, HIGH); // apply +18V to EA to activate Programming-Mode
  programMode = 1;
  burnAddress = 0;
}

void endFirmware() {
  programMode = 0;
  setFirstStage();
}

uint8_t burnByte(uint8_t sendByte) {
  int currentAddress = burnAddress;
  for(int j = 0; j < ADDRESS_SIZE; j++){
    pinMode(portAddress[j], OUTPUT);
    digitalWrite(portAddress[j], currentAddress & 0x01);
    currentAddress = currentAddress>>1;
  }
  
  delay(1);
  digitalWrite(RESET, HIGH);
  delay(1);

  uint8_t currentData = sendByte;
  for(int j = 0; j < 8; j++){
    digitalWrite(portAddress[j], currentData & 0x01);
    currentData = currentData >> 1;
  }
  
  delay(1);
  digitalWrite(VDD, HIGH);
  delay(1);
  digitalWrite(PROG, HIGH);
  delay(BURN_TIME);
  digitalWrite(PROG, LOW);
  digitalWrite(VDD, LOW);
  delay(1);

  for(int j = 7; j >= 0; j--){
     pinMode(portAddress[j], INPUT_PULLUP);
  }  
  digitalWrite(TEST0, HIGH);
  delay(1);

  uint8_t verifyData = 0;
  for(int j = 7; j >= 0; j--){
    verifyData = verifyData << 1;
    verifyData |= digitalRead(portAddress[j]);
  }  
  
  digitalWrite(TEST0, LOW);
  digitalWrite(RESET, LOW);
  
  if (verifyData == sendByte){
    return 1;
  } 
  return 0;
}

void readchip(uint16_t count) {
  digitalWrite(TEST0, LOW);
  digitalWrite(EA, HIGH); // apply +18V to EA to activate Programming-Mode
  for(int i = 0; i < count; i++){
    Serial.print(i, HEX);
    Serial.print(": ");
  
    int currentAddress = i;
    for(int j = 0; j < ADDRESS_SIZE; j++){
      pinMode(portAddress[j], OUTPUT);
      digitalWrite(portAddress[j], currentAddress & 0x01);
      currentAddress >>= 1;
    }
    
    delay(1);                         // Wait 1ms to have stable lines
    digitalWrite(RESET, HIGH);        // Latch the Address into the MCS-48 µC

    for(int j = 7; j >= 0; j--){
      pinMode(portAddress[j], INPUT_PULLUP);
    }  
    
    digitalWrite(TEST0, HIGH);
    delay(9);

    uint8_t readData = 0;
    for(int j = 7; j >= 0; j--){
      readData <<= 1;
      readData |= digitalRead(portAddress[j]);
    }  
    
    Serial.println(readData, HEX);
    digitalWrite(TEST0, LOW);
    digitalWrite(RESET, LOW);
  }
  setFirstStage();
}

void checkReceive() {
  if (Serial.available()) {
    uint8_t receivedByte = Serial.read();
    if(programMode>=1 && programMode<=3){
      if(programMode == 3){
         firmwareSize = receivedByte;
         programMode--; 
      } else 
      if(programMode == 2){
         firmwareSize |= receivedByte << 8;
         startFirmware();
         Serial.write(ACK);
      } else
      if(programMode == 1){
        if(burnByte(receivedByte)==1){
          Serial.write(ACK);
          burnAddress++;
          if(burnAddress>=firmwareSize){
            endFirmware();
            Serial.print("OK");
          }
        } else{
          endFirmware();
          Serial.write(NAK);
        }
      }
    } else
    if(programMode>=4 && programMode<=5){
      if(programMode == 5){
         firmwareSize = receivedByte;
         programMode--; 
      } else 
      if(programMode == 4){
         Serial.write(ACK);
         firmwareSize |= receivedByte << 8;
         readchip(firmwareSize);
         endFirmware();
         Serial.println("OK");
      }
    } else {
      if (receivedByte == 10) {
        //Serial.println(receiveCommand);
        if(strncmp(receiveCommand,"burn",4)==0){
          Serial.println("OK");
          programMode=3;
        } else 
        if(strncmp(receiveCommand,"read",4)==0){
          Serial.println("OK");
          programMode=5;
        } else
        if(strncmp(receiveCommand,"start",5)==0){
          Serial.println("MCS-48 Programmer READY");
        } else {
          Serial.println("UNKNOWN");
        }
        receiveCommandPos = 0;
      } else {
        if(receiveCommandPos<5){
          receiveCommand[receiveCommandPos++] = (char)receivedByte;
        }
      }
    }
  }
}
