/*
 * Firmware for GoGo Board Shield for Arduino. 
 * Autor: Lucas Tanure
 * E-mail: ltanure@gmail.com
 */
#include <LiquidCrystal.h>
#include <Servo.h>
#include <Wire.h> //I2C library
#include "shield.h"
#include "evalOpcode.h"
LiquidCrystal lcd(lcd_RS, lcd_E, lcd_D4, lcd_D5, lcd_D6, lcd_D7);// initialize the library with the numbers of the interface pins

//Global Serial Buffer
int gblSerialBufferFirstByte;
int gblSerialBufferLastByte;
int gblSerialBufferNumberBytes; // bytes on buffer serial
int gblSerialBufferReadAttempts; // number of attempts to read the serial buffer
int serialBuffer[SerialBufferSize];

//Global Motor Variables
int gblActiveMotors;
int gblMtrDuty[MotorCount]; // if duty < 0 , motor set to ThatWay, if duty > 0 motor set to ThisWay
int gblMtrMode[MotorCount];
Servo gblMtrServo[MotorCount];
int gblMtrPins[MotorCount*2];
int gblMtrOnOff[MotorCount];

long gblLogoCodeSize;
unsigned int eeaddresspage;
int gblDeviceAddress;
int gblLogoCodeReadBuffer[I2CBufferSize];
int gblLogoCodeWriteBuffer[I2CBufferSize];
boolean glbRuningCodeExecution;
boolean gblStartCodeExecution;
int firsOfThree;

//Logo Code Execution Variables
unsigned int gblMemPtr;
unsigned int  gblFlashBaseAddress;
unsigned long gblTimer;
int gblLoopAddress;
int gblRepeatCount;
int gblOnForWaitCounter;
byte gblMostRecentlyReceivedByte;
boolean gblNewByteHasArrivedFlag;
int globalVariables[16];
boolean gblONFORNeedsToFinish;
unsigned long gblOnForWaitCounterEND;
unsigned long gblOnForWaitCounterStart;


unsigned long gblWAITLogoExecutionCounterEND;
unsigned long gblWAITLogoExecutionCounterStart;
boolean gblWAITLogoExecutionStatus;


//Stack Variables
int gblStackPtr;
int gblInputStackPtr;
int gblStack[STACK_SIZE];
unsigned int gblInputStack[STACK_SIZE];

void initGlobalVariables(){
  gblSerialBufferFirstByte = 0;
  gblSerialBufferLastByte = 0;
  gblSerialBufferNumberBytes = 0; 
  gblSerialBufferReadAttempts = 0;
  gblActiveMotors = 0;
  gblMtrDuty[0] = 1;
  gblMtrDuty[1] = 1;
  gblMtrMode[0] = MOTOR_NORMAL;
  gblMtrMode[1] = MOTOR_NORMAL;
  gblMtrPins[0] = motor_pin_A1;
  gblMtrPins[1] = motor_pin_A2;
  gblMtrPins[2] = motor_pin_B1;
  gblMtrPins[3] = motor_pin_B2;
  gblMtrOnOff[0] = OFF;
  gblMtrOnOff[1] = OFF;
  gblLogoCodeSize = 0;
  eeaddresspage = 0;
  gblDeviceAddress = 0x50;
  firsOfThree = 0;
  glbRuningCodeExecution = false;
  gblStartCodeExecution = false;
  gblSerialBufferLastByte = 0;
  gblSerialBufferFirstByte = 0;
  gblSerialBufferNumberBytes = 0;
  gblActiveMotors = 0;

  initStack();

  //Logo Code Execution Variables
  gblLoopAddress = 0;
  gblRepeatCount = 0;
  gblOnForWaitCounter = 0;
  gblNewByteHasArrivedFlag = false;
  gblONFORNeedsToFinish =  false;
  gblOnForWaitCounterEND = 0;
  gblOnForWaitCounterStart = 0;
}


/*
 * I2C EEPROM CODE
 */

void i2c_eeprom_write_byte(unsigned int eeaddress, byte data ) {
  int rdata = data;
  Wire.beginTransmission(gblDeviceAddress);
  Wire.send((int)(eeaddress >> 8)); // MSB
  Wire.send((int)(eeaddress & 0xFF)); // LSB
  Wire.send(rdata);
  Wire.endTransmission();
}

byte fetchNextOpcode() {// i2c_eeprom_read_byte
  byte rdata = i2c_eeprom_read_byte(FLASH_USER_PROGRAM_BASE_ADDRESS + gblMemPtr);
  gblMemPtr++;
  return rdata;
}


byte i2c_eeprom_read_byte(unsigned int eeaddress ) {
  byte rdata = 0xFF;
  Wire.beginTransmission(gblDeviceAddress);
  Wire.send((int)(eeaddress >> 8)); // MSB
  Wire.send((int)(eeaddress & 0xFF)); // LSB
  Wire.endTransmission();
  Wire.requestFrom(gblDeviceAddress,1);
  if (Wire.available()) rdata = Wire.receive();
  return rdata;
}

// End I2C EEPROM


void beep(){
  digitalWrite(beep_pin, HIGH);
  delay(35);              
  digitalWrite(beep_pin, LOW);
  delay(35);
}

void MotorON(int MotorNo) {
  gblMtrOnOff[MotorNo] = ON;
  if(gblMtrDuty[MotorNo] >=0 ){// this way
    analogWrite(gblMtrPins[MotorNo*2], gblMtrDuty[MotorNo]);
    analogWrite(gblMtrPins[MotorNo*2+1], 0);
  }
  else{// that way
    analogWrite(gblMtrPins[MotorNo*2+1], -1 * gblMtrDuty[MotorNo]);
    analogWrite(gblMtrPins[MotorNo*2], 0);
  }
}

void MotorOFF(int MotorNo) {
  gblMtrOnOff[MotorNo] = OFF;
  analogWrite(gblMtrPins[MotorNo*2],0);
  analogWrite(gblMtrPins[MotorNo*2+1],0);
}

void MotorRD(int MotorNo) {
  gblMtrDuty[MotorNo] = gblMtrDuty[MotorNo] * (-1);
  if(gblMtrOnOff[MotorNo] == ON){
    MotorON(MotorNo);
  }
}

void MotorThisWay(int MotorNo) {
  if(gblMtrDuty[MotorNo] < 0 ){
    gblMtrDuty[MotorNo] *= (-1); 
  }
  if(gblMtrOnOff[MotorNo] == ON){
    MotorON(MotorNo);
  }
}


void MotorThatWay(int MotorNo) {
  if(gblMtrDuty[MotorNo] >= 0 ){
    gblMtrDuty[MotorNo] *= (-1); 
  }
  if(gblMtrOnOff[MotorNo] == ON){
    MotorON(MotorNo);
  }
}

void SetMotorMode(int MotorNo, int mode){
  if(mode == MOTOR_NORMAL){
    gblMtrMode[MotorNo] = MOTOR_NORMAL;
    if(gblMtrServo[MotorNo].attached()){
      gblMtrServo[MotorNo].detach();
    }
  }
  else{
    MotorOFF(MotorNo);
    gblMtrMode[MotorNo] = MOTOR_SERVO;
    gblMtrServo[MotorNo].attach(gblMtrPins[MotorNo*2]);
  }
}


void SetActiveMotorsMode(int mode){
  if (gblActiveMotors % 2 == 1) {// Motor A
    SetMotorMode( 0,mode);
  }
  if ((gblActiveMotors >> 1) % 2 == 1) { // Motor B
    SetMotorMode( 1,mode);
  }
}

boolean MotorControl(int MotorCmd) {
  int MotorNo; 
  boolean done = false;
  for (MotorNo=0;MotorNo<MotorCount;MotorNo++) {
    if ((gblActiveMotors >> MotorNo) & 1) {
      SetMotorMode(MotorNo,MOTOR_NORMAL);
      switch (MotorCmd) {
      case CMD_MTR_ON:
        MotorON(MotorNo);
        done = true;
        break;
      case CMD_MTR_OFF:
        MotorOFF(MotorNo);
        done = true;
        break;
      case CMD_MTR_REVERSE:
        MotorRD(MotorNo);
        done = true;
        break;
      case CMD_MTR_THISWAY:
        MotorThisWay(MotorNo);
        done = true;
        break;
      case CMD_MTR_THATWAY:
        MotorThatWay(MotorNo);
        done = true;
        break;
      case CMD_MTR_COAST:
        //MotorCoast(MotorNo);
        done = true;
        break;
      }
    }
  }
  return done;
}

void SetMotorServoAngle(int MotorNo, int angle){
  if(gblMtrMode[MotorNo] == MOTOR_SERVO){
    gblMtrServo[MotorNo].write(angle);
  }
}

void SetActiveMotorServoAngle(int angle){
  if (gblActiveMotors % 2 == 1) {// Motor A
    SetMotorServoAngle( 0,angle);
  }
  if ((gblActiveMotors >> 1) % 2 == 1) { // Motor B
    SetMotorServoAngle( 1,angle);
  }
}

void SetMotorPower(int Power) {
  switch (Power) {
  case 0:
    Power = 1;
    break;
  case 1:
    Power = 36;
    break;
  case 2:
    Power = 75;
    break;
  case 3:
    Power = 110;
    break;
  case 4:
    Power = 147;
    break;
  case 5:
    Power = 183;
    break;
  case 6:
    Power = 219;
    break;
  case 7:
    Power = 255;
    break;
  }
  if (gblActiveMotors % 2 == 1) {// Motor A
    if(gblMtrDuty[0] >= 0 ){ // this way ?
      gblMtrDuty[0] = Power;
    }
    else{
      gblMtrDuty[0] = Power * (-1); // that way
    }
    if(gblMtrOnOff[0] == ON){
      MotorON(0);
    }
  }
  if ((gblActiveMotors >> 1) % 2 == 1) { // Motor B
    if(gblMtrDuty[1] >= 0 ){ // this way ?
      gblMtrDuty[1] = Power;
    }
    else{
      gblMtrDuty[1] = Power * (-1); // that way
    }
    if(gblMtrOnOff[1] == ON){
      MotorON(1);
    }
  }

}

void TalkToMotor(int MotorBits) {
  gblActiveMotors = MotorBits;
}

int readSensor(int sensor){
  if(sensor >=0 && sensor <=3){
    return analogRead(sensor);
  }
  return 0;
}

/*
 *  Buffer Serial Functions
 */

void copyBufferSerial() {
  while(gblSerialBufferNumberBytes != SerialBufferSize && Serial.available() > 0) {
    Serial.print(Serial.peek(),BYTE);
    byte inByte = Serial.read();

    gblMostRecentlyReceivedByte = inByte;

    gblSerialBufferNumberBytes++;
    gblSerialBufferLastByte = (gblSerialBufferLastByte +1) % SerialBufferSize;
    serialBuffer[gblSerialBufferLastByte] = inByte;
  }
}

byte readBuffer() {
  if (gblSerialBufferNumberBytes > 0) {
    gblSerialBufferNumberBytes--;
    gblSerialBufferFirstByte = (gblSerialBufferFirstByte +1) % SerialBufferSize;
    return serialBuffer[gblSerialBufferFirstByte];
  }
}

byte mustReadBuffer() {
  while(gblSerialBufferNumberBytes == 0){
    copyBufferSerial();
  }
  if (gblSerialBufferNumberBytes > 0) {
    gblSerialBufferNumberBytes--;
    gblSerialBufferFirstByte = (gblSerialBufferFirstByte +1) % SerialBufferSize;
    return serialBuffer[gblSerialBufferFirstByte];
  }
}

void ack(){
  Serial.print(ReplyHeader1,BYTE);
  Serial.print(ReplyHeader2,BYTE);
  Serial.print(ACK_BYTE,BYTE);
}

void processSerial(){
  byte inByte = readBuffer();
  if( inByte == CMD_CONNECT){
    if(mustReadBuffer() == 0){
      Serial.print(55,BYTE);
      return;
    }
  }
  else if(inByte == CMD_BEEP){
    if(mustReadBuffer() == 0){
      beep();
    }
  }
  else if(inByte == CMD_SET_PTR){
    byte Hi, Low;
    Hi = mustReadBuffer();
    Low = mustReadBuffer();
    gblMemPtr = (unsigned int) byteToint(Hi, Low);
    gblFlashBaseAddress = FLASH_USER_PROGRAM_BASE_ADDRESS + gblMemPtr;
  }
  else if(inByte >= 32 && inByte <= 60){
    int sensor = (inByte - 32)/4;
    int value = readSensor(sensor);
    Serial.print(ReplyHeader1,BYTE);
    Serial.print(ReplyHeader2,BYTE);
    Serial.print(value >> 8,BYTE);
    Serial.print(value & 0xff,BYTE);
    return;
  }
  else if (inByte == CMD_TALK_MOTOR){
    inByte = mustReadBuffer();
    if(inByte < 4 ){
      gblActiveMotors = inByte;
    }
    ack();
    return;
  }
  else if (MotorControl(inByte)){
    return;
  }
  else if(inByte >= CMD_MTR_POWER && inByte <= 124){
    inByte -= CMD_MTR_POWER;
    inByte /= 4;
    SetMotorPower(inByte);
  }

  else if (inByte == CMD_MTR_DUTY){
    inByte = mustReadBuffer();
    int MotorNo;
    for (MotorNo=0;MotorNo<MotorCount;MotorNo++) {
      if ((gblActiveMotors >> MotorNo) & 1) {
        SetMotorMode(MotorNo,MOTOR_SERVO);
        SetMotorServoAngle(MotorNo, inByte);
      }
    }  
  }
  else if (inByte == CMD_WRITE_LOGO_CODE){
    inByte = mustReadBuffer();
    gblLogoCodeSize = (long) inByte * 256;
    inByte = mustReadBuffer();
    gblLogoCodeSize += inByte;
    unsigned int ptr = gblFlashBaseAddress;
    for (ptr = gblFlashBaseAddress; ptr<gblLogoCodeSize+gblFlashBaseAddress; ptr++){
      inByte = mustReadBuffer();
      i2c_eeprom_write_byte(ptr,inByte);
    }
  }
}

int byteToint(byte Hi, byte Low){
  int inter;
  inter = (unsigned int)Hi;
  inter = inter <<8;
  inter += (unsigned int) Low;
  return inter;
}


void setup() {
  lcd.begin(16, 2); // set up the LCD's number of columns and rows: 
  Serial.begin(9600);
  Wire.begin();
  pinMode( motor_pin_A1,   OUTPUT);
  pinMode( motor_pin_A2,   OUTPUT);
  pinMode( motor_pin_B1,   OUTPUT);
  pinMode( motor_pin_B2,   OUTPUT);
  pinMode( beep_pin,       OUTPUT);
  pinMode( run_button_pin, INPUT);
  digitalWrite(run_button_pin, HIGH); //run logo code button pull up
  digitalWrite(A0, HIGH); //sensor pull up
  digitalWrite(A1, HIGH); //sensor pull up
  digitalWrite(A2, HIGH); //sensor pull up
  digitalWrite(A3, HIGH); //sensor pull up
  attachInterrupt(0, RunStopCodeExecution, RISING);
  initCodeExecutionVariables();
  initGlobalVariables();
  lcd.clear();
  lcd.setCursor(0, 0);
}

void RunStopCodeExecution(){
  if(!glbRuningCodeExecution){
    gblStartCodeExecution = true;
  }
  glbRuningCodeExecution = ~(glbRuningCodeExecution);
}

void loop() {
  for (gblSerialBufferReadAttempts =0 ;gblSerialBufferReadAttempts < MaxAttempts ;gblSerialBufferReadAttempts++){
    if(Serial.available() > 0 && gblSerialBufferNumberBytes != SerialBufferSize) {
      copyBufferSerial();
    }
  }
  if(gblSerialBufferNumberBytes > 0 && !(Serial.available() > 0 && gblSerialBufferNumberBytes != SerialBufferSize)){
    processSerial();
  }

  if(gblONFORNeedsToFinish){
    if(gblOnForWaitCounterEND + gblOnForWaitCounterStart <= millis()){
      gblONFORNeedsToFinish =  false;
      evalOpcode(M_OFF);
    }
  }
  
  if(gblWAITLogoExecutionStatus){
    if(gblWAITLogoExecutionCounterEND + gblWAITLogoExecutionCounterStart <= millis()){
      gblWAITLogoExecutionStatus =  false;
    }
  }
  
  if(glbRuningCodeExecution){
    if(gblStartCodeExecution){
      gblStartCodeExecution = false;
      clearStack();
      byte Hi, Low;
      Hi = i2c_eeprom_read_byte(RUN_BUTTON_BASE_ADDRESS);
      Low = i2c_eeprom_read_byte(RUN_BUTTON_BASE_ADDRESS+1);
      gblMemPtr = (unsigned int)Hi;
      gblMemPtr = gblMemPtr <<8;
      gblMemPtr += (unsigned int) Low;
    }
    if(!gblWAITLogoExecutionStatus){
      evalOpcode(fetchNextOpcode());
    }
  }
}
