/////////////////////////////////////////////
//  Main Data Stack

void stkPush(unsigned int stackItem) {
  if (gblStackPtr<STACK_SIZE) {
    gblStack[gblStackPtr] = stackItem;
    gblStackPtr++;
  }
}

unsigned int stkPop(void) {
  if (gblStackPtr>0) {
    gblStackPtr--;
    return gblStack[gblStackPtr];
  }
  else{
    return 0;
  }
}

void inputPush(unsigned int stackItem) {
  if (gblInputStackPtr<STACK_SIZE) {
    gblInputStack[gblInputStackPtr] = stackItem;
    gblInputStackPtr++;
  } 
}

unsigned int inputPop(void) {
  if (gblInputStackPtr>=0) {
    gblInputStackPtr--;
    return(gblInputStack[gblInputStackPtr]);
  } 
}

void clearStack() {
  gblStackPtr=gblInputStackPtr=0;
}

void initStack(){
  gblInputStackPtr = 0;
  gblStackPtr = 0;
}
