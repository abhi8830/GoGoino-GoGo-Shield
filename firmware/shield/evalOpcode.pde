/*
 * Firmware for GoGo Board Shield for Arduino. 
 * Autor: Lucas Tanure
 * E-mail: ltanure@gmail.com
 */

void initCodeExecutionVariables(){
  gblMemPtr = 0;
  gblLoopAddress = 0;
  gblRepeatCount= 0;
  gblNewByteHasArrivedFlag = false;
  glbRuningCodeExecution = false;
  
  //wait 
  gblWAITLogoExecutionCounterEND = 0;
  gblWAITLogoExecutionCounterStart = 0;
  gblWAITLogoExecutionStatus = false;
  
  //OnFor
  gblOnForWaitCounterEND = 0;
  gblOnForWaitCounterStart = 0;
  gblONFORNeedsToFinish = false;
  
}

void evalOpcode(byte opcode) {
  int i,temp;
  signed int opr1, opr2, opr3; // CCS Default is Unsigned 
  unsigned int genPurpose=0;
  // if opcode is a prcedure call (msb is 1)

  if (opcode & 0b10000000) {
    Serial.print("Entrei\n");
    genPurpose=gblMemPtr+1; // this is the return address
    gblMemPtr = fetchNextOpcode();
    // then fetch the new opcode
    // The first opcode in a procedure is the number of parameters.
    opr1 = fetchNextOpcode();
    /// if the second msb is set -> tail recursion
    if (opcode & 0b01000000) {
      // - Because this is tail recursion, we have to overwrite preveous procedure inputs
      // with the new ones. This loop removes the old inputs.
      // - In addition to the procedure input we have three extra entries: the data stack pointer ,
      // the procedure return address, and the procedure input base address in the input stack.
      for (i=0 ; i < (opr1+3) ; i++) {
        inputPop();
      }
    }

    // Pop the procedure inputs from the main data stack and move them to the input stack
    for (i=0 ; i<opr1 ; i++) {
      inputPush(stkPop());
    }

    inputPush(gblStackPtr); // save the data stack pointer (we use this with STOP opcode to clear the
    // data stack of the current procedure.
    inputPush(genPurpose); // save the return address

    inputPush(gblInputStackPtr - (opr1+2)); // pushes a proc input base address index.
    // you'll need to read the documentation
    // to fully understand why. Meanwhile, see how it
    // is used in case LTHING
    // - we add 2 because we also keep the data stack pointer and
    // the return address in this stack.

    return;
  }


  ////////////////////////////////////////////////////////////////////////////////////////

  switch (opcode) {
  case CODE_END:
    glbRuningCodeExecution = false;
    // clear thes variables just in case.
    gblLoopAddress = 0;
    gblRepeatCount = 0;
    break;
  case NUM8:
    temp = fetchNextOpcode();
    Serial.print(temp,DEC);
    stkPush(temp);
    break;
  case NUM16:
    byte Hi,Low;
    Hi = fetchNextOpcode();
    Low = fetchNextOpcode();
    stkPush((unsigned int) byteToint(Hi, Low));
    break;
  case LIST:
    stkPush(gblMemPtr+1);
    gblMemPtr += fetchNextOpcode();
    break;
  case EOL:
    Serial.print("EOL ");
    genPurpose = stkPop();
    if (genPurpose > gblMemPtr) {
      gblMemPtr = genPurpose;
    } 
    else {
      gblMemPtr = genPurpose;
      gblRepeatCount = stkPop(); // repeat count
      Serial.print(gblRepeatCount,DEC);
      Serial.print(" \n");
      if (gblRepeatCount > 0){
        gblRepeatCount--;
      }
      if (gblRepeatCount != 0) {
        stkPush(gblRepeatCount);
        stkPush(gblMemPtr);
      }
    }
    break;
  case EOLR:
    if (stkPop()) { // if condition is true
      stkPop(); // throw away the loop address
      gblMemPtr = stkPop(); // fetch the next command address
    } 
    else { // if condition if false -> keep on looping.
      gblMemPtr = stkPop();
      stkPush(gblMemPtr);
      delay(5); // this prevents the waituntil loop to execute too rapidly
      // which has proven to cause some problems when reading
      // sensor values.
    }
    break;

    /////////////////////////////////////////////////////////////
    // retrieve procedure input
  case LTHING:
    // genPurpose = 2*fetchNextOpcode(); // index of the input variable
    genPurpose = fetchNextOpcode(); // In this case it is not required because the input stack is unisgned int 16
    opr1 = inputPop(); // base address in the input stack
    inputPush(opr1); // push the base address back to the stack.
    stkPush(gblInputStack[opr1 + genPurpose]);
    break;

    /////////////////////////////////////////////////////////////
    // return to the parent procedure
  case STOP:
  case OUTPUT_:
    if (opcode == OUTPUT_)
      genPurpose = stkPop(); // this is the output value
    opr1 = inputPop(); // this is the proc-input stack base address
    gblMemPtr = inputPop(); // this is the return address
    opr2 = inputPop(); // this is the data stack index;
    // remove any remaining data that belongs to the current procedure from the data stack
    // Usually this is important for the STOP opcode.
    while (gblStackPtr > opr2)
      stkPop();
    // remove the procedure inputs from the input stack
    while (gblInputStackPtr > opr1)
      inputPop();
    // Output will push the output to the stack
    if (opcode == OUTPUT_)
      stkPush(genPurpose);
    break;

  case REPEAT:
    Serial.print("REPEAT\n");
    gblLoopAddress = stkPop();
    gblRepeatCount = stkPop();
    // these will be poped by EOL
    stkPush(gblMemPtr); // address after repeat is complete

    if (gblRepeatCount > 1) {
      stkPush(gblRepeatCount);
      stkPush(gblLoopAddress); // address while still repeating
      gblMemPtr = gblLoopAddress;
    } 
    else if (gblRepeatCount == 1) {
      gblMemPtr = gblLoopAddress;
    } 
    else { // if loop count = 0
      gblMemPtr = stkPop();
    }
    break;

  case COND_IF:
    opr1=stkPop(); // if true pointer address
    opr2=stkPop(); // condition
    if (opr2) {
      stkPush(gblMemPtr);
      gblMemPtr=opr1;
    }
    break;

  case COND_IFELSE:
    opr1=stkPop(); // if false pointer address
    opr2=stkPop(); // if true pointer address
    opr3=stkPop(); // condition
    stkPush(gblMemPtr);
    if (opr3) {
      gblMemPtr=opr2;
    } 
    else {
      gblMemPtr=opr1;
    }
    break;

  case BEEP:
    beep();
    break;

  case NOTE:
    break;

  case WAITUNTIL:
    gblLoopAddress = stkPop();
    // these will be poped by EOLR
    stkPush(gblMemPtr); // address after repeat is complete
    stkPush(gblLoopAddress); // address while still repeating
    gblMemPtr = gblLoopAddress;
    break;

  case LOOP:
    gblLoopAddress = stkPop(); // the begining of loop
    gblRepeatCount = 0; // disable this counter (loop forever)
    stkPush(0); // this distinguishes LOOP from Repeat. (see EOL)
    stkPush(gblLoopAddress); // push loop address back into the stack
    // so that EOL will loop
    gblMemPtr = gblLoopAddress;
    break;

  case WAIT:
    gblWAITLogoExecutionCounterEND = 100 * stkPop();
    gblWAITLogoExecutionCounterStart = millis();
    gblWAITLogoExecutionStatus = true;
    break;

  case TIMER:
    stkPush(gblTimer); // gblTimer increases every 1ms.
    break;

  case RESETT:
    gblTimer = millis();
    break;

  case SEND:
    genPurpose = stkPop();
    Serial.print(genPurpose);
    break;

  case IR:
    stkPush(gblMostRecentlyReceivedByte);
    gblNewByteHasArrivedFlag = false;
    break;

  case NEWIR:
    stkPush(gblNewByteHasArrivedFlag);
    break;

  case RANDOM:
    stkPush(rand());
    break;

  case OP_PLUS:
  case OP_MINUS:
  case OP_MULTIPLY:
  case OP_DIVISION:
  case OP_REMAINDER:
  case OP_EQUAL:
  case OP_GREATER:
  case OP_LESS:
  case OP_AND:
  case OP_OR:

  case OP_XOR:
    opr2=stkPop(); // second operand
    opr1=stkPop(); // first operand
    switch (opcode) {
    case OP_PLUS:
      opr1+=opr2;
      break;
    case OP_MINUS:
      opr1-=opr2;
      break;
    case OP_MULTIPLY:
      opr1*=opr2;
      break;
    case OP_DIVISION:
      opr1/=opr2;
      break;
    case OP_REMAINDER:
      opr1%=opr2;
      break;
    case OP_EQUAL:
      opr1=(opr1==opr2);
      break;
    case OP_GREATER:
      opr1=(opr1>opr2);
      break;
    case OP_LESS:
      opr1=(opr1<opr2);
      break;
    case OP_AND:
      opr1=(opr1&&opr2);
      break;
    case OP_OR:
      opr1=(opr1||opr2);
      break;
    case OP_XOR:
      opr1=(opr1^opr2);
      break;
    };
    stkPush(opr1);
    break;

  case OP_NOT:
    stkPush(!stkPop());
    break;

    ///////////////////////////////////////////////////////////////////////
    // Global variables
  case SETGLOBAL:
    genPurpose = stkPop(); // this is the value
    globalVariables[stkPop()] = genPurpose;
    break;
  case GETGLOBAL:
    stkPush(globalVariables[stkPop()]);
    break;
    /*
 ///////////////////////////////////////////////////////////////////////
     // Global Array
     
     case ASET:
     opr2 = stkPop(); // this is the value to be stored
     opr1 = stkPop() * 2; // this is the array index. Each entry is two bytes wide.
     genPurpose = ARRAY_BASE_ADDRESS + stkPop(); // this is the base address of the array.
     
     flashSetWordAddress(genPurpose + opr1);
     flashWrite(opr2);
     
     break;
     case AGET:
     opr1 = stkPop() * 2; // this is the array index. Each entry is two bytes wide.
     genPurpose = ARRAY_BASE_ADDRESS + stkPop(); // this is the base address of the array.
     opr2 = read_program_eeprom(genPurpose + opr1);
     stkPush(opr2);
     
     
     break;
     
     /////////////////////////////////////////////////////////////////////////
     // Data collection commands
     
     case RECORD:
     genPurpose = stkPop();
     
     // PCM parts (14 bit PICs like the 16F877) uses an external EEPROM
     // for data Logging storage
     
     flashSetWordAddress(RECORD_BASE_ADDRESS + gblRecordPtr++);
     gblRecordPtr++; // The record variable is 16 bit so it requires to increase by 2 
     
     flashWrite(genPurpose);
     
     // save current record pointer location
     flashSetWordAddress(MEM_PTR_LOG_BASE_ADDRESS);
     flashWrite(gblRecordPtr);
     break;
     
     case RECALL:
     genPurpose = read_program_eeprom(RECORD_BASE_ADDRESS + gblRecordPtr++);
     gblRecordPtr++; // To adjust the pointer for two bytes
     stkPush(genPurpose);
     break;
     
     case RESETDP:
     gblRecordPtr = 0;
     break;
     
     case SETDP:
     gblRecordPtr = stkPop() * 2;
     break;
     
     case ERASE:
     opr1 = stkPop() * 2;
     for (genPurpose=0 ; genPurpose<opr1 ; genPurpose++) {
     flashSetWordAddress(RECORD_BASE_ADDRESS + genPurpose);
     flashWrite(0);
     }
     gblRecordPtr = 0;
     break;
     */

//end of the first eval opcode function from Br-Gogo

  case  WHEN:
    break;
  case  WHENOFF:
    break;
  case  M_A:
    gblActiveMotors = 1;
    break;
  case  M_B:
    gblActiveMotors = 2;
    break;
  case  M_AB:
    gblActiveMotors = 3;
    break;

    //////////////////////////////////////////////////////

    // Look at how M_ON, M_ONFOR, and M_OFF work carefully.
    // - M_ON, M_ONFOR starts by turning motors on.
    // - M_ON breaks right after while M_ONFOR continues.

  case  M_OFF:
    MotorControl(CMD_MTR_OFF);
    break;
  case  M_THATWAY:
    MotorControl(CMD_MTR_THATWAY);
    break;
  case  M_THISWAY:
    MotorControl(CMD_MTR_THISWAY);
    break;
  case  M_RD:
    MotorControl(CMD_MTR_REVERSE);
    break;
  case  BRAKE:
    MotorControl(CMD_MTR_COAST);
    break;
  case  M_ON:
  case  M_ONFOR:
    MotorControl(CMD_MTR_ON);
    if (opcode == M_ONFOR) {
      gblOnForWaitCounterEND = 100*stkPop();
      gblOnForWaitCounterStart = millis();
      gblONFORNeedsToFinish = true;
    }
    break;
  case  SETPOWER:
    SetMotorPower(stkPop());
    break;

  case  BSEND:
  case  BSR:
    // These two opcodes are not supported.
    break;
  case  M_C:
    //arduino don't have motor c
    break;
  case  M_D:
    //arduino don't have motor d
    break;
  case  M_CD:
    //arduino don't have motor c and d
    break;
  case  M_ABCD:
    gblActiveMotors = 3;
    break;

  case  REALLY_STOP:
    glbRuningCodeExecution = false;
    break;

  case  EB:  // reads byte from memory
    //stkPush(read_program_eeprom(stkPop()));
    break;
/*
  case  DB:  // deposit byte to memory
    /// Note: I have checked this code. I might have swapped opr1 and opr2
    opr1 = stkPop(); // value to write
    opr2 = stkPop(); // memory address
    flashSetWordAddress(opr2);
    flashWrite(opr1);
    break;
*/
  case  LOW_BYTE:  // returns low byte
    stkPush(stkPop() & 0xff);
    break;
  case  HIGH_BYTE:  // returns high byte
    stkPush(stkPop() >> 8);
    break;

    ///////////////////////////////////////////////////
    //  The following code are unique to the GoGo board
    /// read sensor
  case  SENSOR1:
  case  SENSOR2:
  case  SENSOR3:
  case  SENSOR4:
  case  SENSOR5:
  case  SENSOR6:
  case  SENSOR7:
  case  SENSOR8:
    // we need the following IF because the opcode for sensor1&2 are separate from the rest.
    // If this wasn't the case we could have just done .. i = opcode - SENSOR1;
    if (opcode < SENSOR3) {
      i = opcode - SENSOR1;
    } 
    else {
      i = opcode - SENSOR3 + 2;
    }

    stkPush(readSensor(i));
    break;

    // read sensor and treat it as a on-off switch (0 or 1)
  case  SWITCH1:
  case  SWITCH2:
  case  SWITCH3:
  case  SWITCH4:
  case  SWITCH5:
  case  SWITCH6:
  case  SWITCH7:
  case  SWITCH8:
    if (opcode < SWITCH3) {
      i = opcode - SWITCH1;
    } 
    else {
      i = opcode - SWITCH3 + 2;
    }

    stkPush(readSensor(i)>>9);
    break;

    /////////////////////////////////////////////////////////////
    //  user LED control
  case ULED_ON:
    // arduino don't have a user led
    break;
  case ULED_OFF:
    // arduino don't have a user led
    break;


    /////////////////////////////////////////////////////////////
    //  Servo controls

  case SERVO_SET_H:
  case SERVO_LT:
  case SERVO_RT:
    MotorControl(CMD_MTR_ON);
    SetActiveMotorsMode(MOTOR_SERVO);
    i = stkPop();
    SetActiveMotorServoAngle(i);
    break;

  case TALK_TO_MOTOR:
    opr1 = stkPop(); // this is the motor bits
    TalkToMotor(opr1);
    break;

    ///////////////////////////////////////////////////////////
    //
    //  I2C  Commands
    //

  case CL_I2C_START:
    //i2c_start(); already do by setup
    break;

  case CL_I2C_STOP:
    //i2c_stop(); //Nevr Do do this for arduino
    break;

  case CL_I2C_WRITE:
    i = stkPop();
    Wire.send(i);
    break;

  case CL_I2C_READ:
    byte rdata = 0xFF; 
    if (Wire.available()) rdata = Wire.receive();
    stkPush(rdata);
    break;
  };

}


