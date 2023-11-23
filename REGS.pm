package REGS;

use strict;
use warnings;

our $I2C_ADDR = 0x18;
our $CHIP_ID = 0xE26A;
our $CHIP_VERSION = 2;

our $REG_CHIP_ID_L = 0xfa;
our $REG_CHIP_ID_H = 0xfb;
our $REG_VERSION = 0xfc;

# Rotary encoder
our $REG_ENC_EN = 0x04;
our $BIT_ENC_EN_1 = 0;
our $BIT_ENC_MICROSTEP_1 = 1;
our $BIT_ENC_EN_2 = 2;
our $BIT_ENC_MICROSTEP_2 = 3;
our $BIT_ENC_EN_3 = 4;
our $BIT_ENC_MICROSTEP_3 = 5;
our $BIT_ENC_EN_4 = 6;
our $BIT_ENC_MICROSTEP_4 = 7;

our $REG_ENC_1_CFG = 0x05;
our $REG_ENC_1_COUNT = 0x06;
our $REG_ENC_2_CFG = 0x07;
our $REG_ENC_2_COUNT = 0x08;
our $REG_ENC_3_CFG = 0x09;
our $REG_ENC_3_COUNT = 0x0A;
our $REG_ENC_4_CFG = 0x0B;
our $REG_ENC_4_COUNT = 0x0C;

# Cap touch
our $REG_CAPTOUCH_EN = 0x0D;
our $REG_CAPTOUCH_CFG = 0x0E;
our $REG_CAPTOUCH_0 = 0x0F;   # First of 8 bytes from 15-22

# Switch counters
our $REG_SWITCH_EN_P0 = 0x17;
our $REG_SWITCH_EN_P1 = 0x18;
our $REG_SWITCH_P00 = 0x19;   # First of 8 bytes from 25-40
our $REG_SWITCH_P10 = 0x21;   # First of 8 bytes from 33-49

our $REG_P0 = 0x40;       # protect_bits 2 # Bit addressing
our $REG_SP = 0x41;       # Read only
our $REG_DPL = 0x42;      # Read only
our $REG_DPH = 0x43;      # Read only
our $REG_RCTRIM0 = 0x44;  # Read only
our $REG_RCTRIM1 = 0x45;  # Read only
our $REG_RWK = 0x46;
our $REG_PCON = 0x47;     # Read only
our $REG_TCON = 0x48;
our $REG_TMOD = 0x49;
our $REG_TL0 = 0x4a;
our $REG_TL1 = 0x4b;
our $REG_TH0 = 0x4c;
our $REG_TH1 = 0x4d;
our $REG_CKCON = 0x4e;
our $REG_WKCON = 0x4f;    # Read only
our $REG_P1 = 0x50;       # protect_bits 3 6 # Bit addressing
our $REG_SFRS = 0x51;     # TA protected # Read only
our $REG_CAPCON0 = 0x52;
our $REG_CAPCON1 = 0x53;
our $REG_CAPCON2 = 0x54;
our $REG_CKDIV = 0x55;
our $REG_CKSWT = 0x56;    # TA protected # Read only
our $REG_CKEN = 0x57;     # TA protected # Read only
our $REG_SCON = 0x58;
our $REG_SBUF = 0x59;
our $REG_SBUF_1 = 0x5a;
our $REG_EIE = 0x5b;      # Read only
our $REG_EIE1 = 0x5c;     # Read only
our $REG_CHPCON = 0x5f;   # TA protected # Read only
our $REG_P2 = 0x60;       # Bit addressing
our $REG_AUXR1 = 0x62;
our $REG_BODCON0 = 0x63;  # TA protected
our $REG_IAPTRG = 0x64;   # TA protected # Read only
our $REG_IAPUEN = 0x65;   # TA protected # Read only
our $REG_IAPAL = 0x66;    # Read only
our $REG_IAPAH = 0x67;    # Read only
our $REG_IE = 0x68;       # Read only
our $REG_SADDR = 0x69;
our $REG_WDCON = 0x6a;    # TA protected
our $REG_BODCON1 = 0x6b;  # TA protected
our $REG_P3M1 = 0x6c;
our $REG_P3S = 0xc0;      # Page 1 # Reassigned from 0x6c to avoid collision
our $REG_P3M2 = 0x6d;
our $REG_P3SR = 0xc1;     # Page 1 # Reassigned from 0x6d to avoid collision
our $REG_IAPFD = 0x6e;    # Read only
our $REG_IAPCN = 0x6f;    # Read only
our $REG_P3 = 0x70;       # Bit addressing
our $REG_P0M1 = 0x71;     # protect_bits  2
our $REG_P0S = 0xc2;      # Page 1 # Reassigned from 0x71 to avoid collision
our $REG_P0M2 = 0x72;     # protect_bits  2
our $REG_P0SR = 0xc3;     # Page 1 # Reassigned from 0x72 to avoid collision
our $REG_P1M1 = 0x73;     # protect_bits  3 6
our $REG_P1S = 0xc4 ;     # Page 1 # Reassigned from 0x73 to avoid collision
our $REG_P1M2 = 0x74;     # protect_bits  3 6
our $REG_P1SR = 0xc5;     # Page 1 # Reassigned from 0x74 to avoid collision
our $REG_P2S = 0x75;
our $REG_IPH = 0x77;      # Read only
our $REG_PWMINTC = 0xc6;  # Page 1 # Read only # Reassigned from 0x77 to avoid collision
our $REG_IP = 0x78;       # Read only
our $REG_SADEN = 0x79;
our $REG_SADEN_1 = 0x7a;
our $REG_SADDR_1 = 0x7b;
our $REG_I2DAT = 0x7c;    # Read only
our $REG_I2STAT = 0x7d;   # Read only
our $REG_I2CLK = 0x7e;    # Read only
our $REG_I2TOC = 0x7f;    # Read only
our $REG_I2CON = 0x80;    # Read only
our $REG_I2ADDR = 0x81;   # Read only
our $REG_ADCRL = 0x82;
our $REG_ADCRH = 0x83;
our $REG_T3CON = 0x84;
our $REG_PWM4H = 0xc7;    # Page 1 # Reassigned from 0x84 to avoid collision
our $REG_RL3 = 0x85;
our $REG_PWM5H = 0xc8;    # Page 1 # Reassigned from 0x85 to avoid collision
our $REG_RH3 = 0x86;
our $REG_PIOCON1 = 0xc9;  # Page 1 # Reassigned from 0x86 to avoid collision
our $REG_TA = 0x87;       # Read only
our $REG_T2CON = 0x88;
our $REG_T2MOD = 0x89;
our $REG_RCMP2L = 0x8a;
our $REG_RCMP2H = 0x8b;
our $REG_TL2 = 0x8c;
our $REG_PWM4L = 0xca;    # Page 1 # Reassigned from 0x8c to avoid collision
our $REG_TH2 = 0x8d;
our $REG_PWM5L = 0xcb;    # Page 1 # Reassigned from 0x8d to avoid collision
our $REG_ADCMPL = 0x8e;
our $REG_ADCMPH = 0x8f;
our $REG_PSW = 0x90;      # Read only
our $REG_PWMPH = 0x91;
our $REG_PWM0H = 0x92;
our $REG_PWM1H = 0x93;
our $REG_PWM2H = 0x94;
our $REG_PWM3H = 0x95;
our $REG_PNP = 0x96;
our $REG_FBD = 0x97;
our $REG_PWMCON0 = 0x98;
our $REG_PWMPL = 0x99;
our $REG_PWM0L = 0x9a;
our $REG_PWM1L = 0x9b;
our $REG_PWM2L = 0x9c;
our $REG_PWM3L = 0x9d;
our $REG_PIOCON0 = 0x9e;
our $REG_PWMCON1 = 0x9f;
our $REG_ACC = 0xa0;      # Read only
our $REG_ADCCON1 = 0xa1;
our $REG_ADCCON2 = 0xa2;
our $REG_ADCDLY = 0xa3;
our $REG_C0L = 0xa4;
our $REG_C0H = 0xa5;
our $REG_C1L = 0xa6;
our $REG_C1H = 0xa7;
our $REG_ADCCON0 = 0xa8;
our $REG_PICON = 0xa9;    # Read only
our $REG_PINEN = 0xaa;    # Read only
our $REG_PIPEN = 0xab;    # Read only
our $REG_PIF = 0xac;      # Read only
our $REG_C2L = 0xad;
our $REG_C2H = 0xae;
our $REG_EIP = 0xaf;      # Read only
our $REG_B = 0xb0 ;       # Read only
our $REG_CAPCON3 = 0xb1;
our $REG_CAPCON4 = 0xb2;
our $REG_SPCR = 0xb3;
our $REG_SPCR2 = 0xcc;    # Page 1 # Reassigned from 0xb3 to avoid collision
our $REG_SPSR = 0xb4;
our $REG_SPDR = 0xb5;
our $REG_AINDIDS0 = 0xb6;
our $REG_AINDIDS1; # Added to have common code with SuperIO
our $REG_EIPH = 0xb7;     # Read only
our $REG_SCON_1 = 0xb8;
our $REG_PDTEN = 0xb9;    # TA protected
our $REG_PDTCNT = 0xba;   # TA protected
our $REG_PMEN = 0xbb;
our $REG_PMD = 0xbc;
our $REG_EIP1 = 0xbe;     # Read only
our $REG_EIPH1 = 0xbf;    # Read only


our $REG_USER_FLASH = 0xD0;
our $REG_FLASH_PAGE = 0xF0;

our $REG_INT = 0xf9;
our $MASK_INT_TRIG = 0x1;
our $MASK_INT_OUT = 0x2;
our $BIT_INT_TRIGD = 0;
our $BIT_INT_OUT_EN = 1;
our $BIT_INT_PIN_SWAP = 2;    # 0 = P1.3, 1 = P0.0

our $REG_INT_MASK_P0 = 0x00;
our $REG_INT_MASK_P1 = 0x01;
our $REG_INT_MASK_P3 = 0x03;

our $REG_ADDR = 0xfd;

our $REG_CTRL = 0xfe;         # 0 = Sleep, 1 = Reset, 2 = Read Flash, 3 = Write Flash, 4 = Addr Unlock
our $MASK_CTRL_SLEEP = 0x1;
our $MASK_CTRL_RESET = 0x2;
our $MASK_CTRL_FREAD = 0x4;
our $MASK_CTRL_FWRITE = 0x8;
our $MASK_CTRL_ADDRWR = 0x10;

our @BIT_ADDRESSED_REGS = ($REG_P0, $REG_P1, $REG_P2, $REG_P3);

# from sioe_regs:
our $REG_PWM0CON0 = 0xaa;
our $REG_PWM0CON1 = 0xab;


1;