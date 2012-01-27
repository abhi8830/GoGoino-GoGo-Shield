// logovm.h - Logo compiler constants and function definitions
//

#define IDLE                     0

/// Comm protocol Sates
#define SET_PTR_HI_BYTE          128
#define SET_PTR_LOW_BYTE         129
#define READ_BYTES_COUNT_HI      130
#define READ_BYTES_COUNT_LOW     131
#define WRITE_BYTES_COUNT_HI     132
#define WRITE_BYTES_COUNT_LOW    133
#define WRITE_BYTES_SENDING      134
#define CRICKET_NAME             135

/// Comm commands
#define SET_PTR         0x83
#define READ_BYTES      0x84
#define WRITE_BYTES     0x85
#define RUN             0x86
#define CRICKET_CHECK   0x87


//////////////////////////////////////
//   Op code
#define  CODE_END             0
#define  NUM8                 1
#define  NUM16                2
#define  LIST                 3
#define  EOL                  4
#define  EOLR                 5
#define  LTHING               6
#define  STOP                 7
#define  OUTPUT_              8 // OUTPUT is reserved word
#define  REPEAT               9
#define  COND_IF              10
#define  COND_IFELSE          11
#define  BEEP                 12
#define  NOTE                 13
#define  WAITUNTIL            14
#define  LOOP                 15
#define  WAIT                 16
#define  TIMER                17
#define  RESETT               18
#define  SEND                 19
#define  IR                   20
#define  NEWIR                21
#define  RANDOM               22
#define  OP_PLUS              23
#define  OP_MINUS             24
#define  OP_MULTIPLY          25
#define  OP_DIVISION          26
#define  OP_REMAINDER         27
#define  OP_EQUAL             28
#define  OP_GREATER           29
#define  OP_LESS              30
#define  OP_AND               31
#define  OP_OR                32
#define  OP_XOR               33
#define  OP_NOT               34
#define  SETGLOBAL            35
#define  GETGLOBAL            36
#define  ASET                 37
#define  AGET                 38
#define  RECORD               39
#define  RECALL               40
#define  RESETDP              41
#define  SETDP                42
#define  ERASE                43
#define  WHEN                 44
#define  WHENOFF              45
#define  M_A                  46
#define  M_B                  47
#define  M_AB                 48
#define  M_ON                 49
#define  M_ONFOR              50
#define  M_OFF                51
#define  M_THISWAY            52
#define  M_THATWAY            53
#define  M_RD                 54
#define  SENSOR1              55
#define  SENSOR2              56
#define  SWITCH1              57
#define  SWITCH2              58
#define  SETPOWER             59
#define  BRAKE                60
#define  BSEND                61
#define  BSR                  62
#define  M_C                  63
#define  M_D                  64
#define  M_CD                 65
#define  M_ABCD               66
#define  FASTSEND             67
#define  REALLY_STOP          68
#define  EB                   69
#define  DB                   70
#define  LOW_BYTE             71
#define  HIGH_BYTE            72

/// These code are unique to the GoGo board
#define  SENSOR3              73
#define  SENSOR4              74
#define  SENSOR5              75
#define  SENSOR6              76
#define  SENSOR7              77
#define  SENSOR8              78
#define  SWITCH3              79
#define  SWITCH4              80
#define  SWITCH5              81
#define  SWITCH6              82
#define  SWITCH7              83
#define  SWITCH8              84

#define ULED_ON               85
#define ULED_OFF              86

#define SERVO_SET_H           87
#define SERVO_LT              88
#define SERVO_RT              89

#define TALK_TO_MOTOR         90

#define CL_I2C_START          91
#define CL_I2C_STOP           92
#define CL_I2C_WRITE          93
#define CL_I2C_READ           94

