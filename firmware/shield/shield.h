// Pins Definitions

#define lcd_RS 13
#define lcd_E  12
#define lcd_D7 4
#define lcd_D6 7
#define lcd_D5 8
#define lcd_D4 11
#define motor_pin_A1 6
#define motor_pin_A2 5
#define motor_pin_B1 3
#define motor_pin_B2 9
#define beep_pin 10
#define run_button_pin 2
#define MotorCount 2


//Protocol Commands
#define ACK_BYTE             0xAA 
#define ReplyHeader1         0x55
#define ReplyHeader2         0xff
#define CMD_CONNECT          135
#define CMD_BEEP             196
#define CMD_TALK_MOTOR       128
#define CMD_MTR_POWER        96
#define CMD_MTR_DUTY         200
#define CMD_MTR_ON           64
#define CMD_MTR_OFF          68
#define CMD_MTR_REVERSE      72
#define CMD_MTR_THISWAY      78
#define CMD_MTR_THATWAY      80 
#define CMD_MTR_COAST        84
#define CMD_WRITE_LOGO_CODE  133
#define CMD_SET_PTR          131

//Data Defines 
#define SerialBufferSize     32
#define I2CBufferSize        30
#define MaxAttempts          10000
#define MOTOR_NORMAL         0
#define MOTOR_SERVO          1
#define STACK_SIZE           32
#define ON                   1
#define OFF                  0


#define RUN_BUTTON_BASE_ADDRESS           600
#define FLASH_USER_PROGRAM_BASE_ADDRESS   0
